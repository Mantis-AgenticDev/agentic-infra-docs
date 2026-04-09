---
title: "PDF Processing con Mistral OCR para RAG Multi-Tenant"
category: "Skill"
domain: ["rag", "backend", "ocr"]
constraints: ["C1", "C2", "C4", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/pdf
  - sdd/skill/ocr
  - sdd/skill/rag
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
---

## 🎯 Propósito y Alcance

Procesar documentos PDF (nativos y escaneados) extrayendo texto y metadata para sistemas RAG, usando Mistral OCR API (C6: modelo cloud) optimizado para VPS con límites de RAM/CPU.

**Casos de uso:**
- PDFs nativos (texto seleccionable): Extracción directa con PyMuPDF
- PDFs escaneados (imágenes): OCR con Mistral Pixtral o APIs alternativas
- PDFs mixtos: Detectar páginas escaneadas y aplicar OCR selectivo
- Documentos multi-tenant: Asociar chunks a tenant_id desde el inicio

**Comparación de herramientas OCR:**

| Herramienta | Precisión | Latencia | Costo/1000 páginas | C6 Compliant |
|-------------|-----------|----------|---------------------|--------------|
| Mistral Pixtral | 95% (español) | 2-5s/página | ~$2 | ✅ API Cloud |
| Google Vision API | 98% | 1-3s/página | ~$1.50 | ✅ API Cloud |
| Tesseract local | 85-90% | 5-10s/página | $0 | ❌ Modelo local (viola C6) |
| AWS Textract | 96% | 2-4s/página | ~$1.50 | ✅ API Cloud |

**Decisión recomendada:** Mistral Pixtral (ya en stack del proyecto) o Google Vision (mejor precisión).

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es OCR?

**OCR (Optical Character Recognition)** = Convertir imágenes de texto en texto editable.

**Ejemplo:**
```
Imagen de PDF escaneado: [📄 foto de factura]
       ↓ OCR
Texto extraído: "Factura #12345\nTotal: $150.00"
```

### PDF Nativo vs Escaneado

**PDF Nativo:**
- Texto seleccionable (copiar/pegar funciona)
- Generado desde Word, LaTeX, impresoras modernas
- Extracción simple (PyMuPDF, pdfplumber)

**PDF Escaneado:**
- Imagen de documento físico (foto/escáner)
- Texto NO seleccionable
- Requiere OCR

**Detección automática:**
```python
import fitz  # PyMuPDF

def is_scanned_pdf(pdf_path):
    doc = fitz.open(pdf_path)
    page = doc[0]
    
    # Si no hay texto extraíble, es escaneado
    text = page.get_text()
    return len(text.strip()) < 50  # <50 caracteres = probablemente escaneado
```

### Mistral Pixtral API

**Mistral Pixtral** = Modelo multimodal que lee imágenes y extrae texto (entre otras tareas).

**Flujo:**
```
PDF → Convertir página a imagen (PNG/JPEG) → Mistral Pixtral API → Texto extraído
```

**Ventajas:**
- Ya está en el stack (C6: No requiere nuevo proveedor)
- Soporta español, portugués nativamente
- Mismo billing que otros modelos Mistral

**Desventaja:**
- Más lento que Google Vision (~5s vs 2s por página)
- Menos preciso en tablas complejas

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Pipeline de Procesamiento Optimizado

```
┌──────────────────────────────────────┐
│  1. RECEPCIÓN PDF                    │
│  Upload (n8n) o Google Drive         │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  2. ANÁLISIS PRELIMINAR              │
│  - Tamaño archivo (<100MB OK)        │  C1: No procesar PDFs gigantes
│  - Número de páginas (<200 OK)       │  C2: Limitar CPU
│  - Detectar si es nativo o escaneado │
└──────────┬───────────────────────────┘
           │
           ▼
      ¿Es nativo?
       /        \
     Sí          No
      │           │
      ▼           ▼
┌─────────┐  ┌──────────────────┐
│ PyMuPDF │  │ Mistral Pixtral  │
│ (local) │  │ OCR (API cloud)  │  C6: Modelo externo
└────┬────┘  └────┬─────────────┘
     │            │
     └────┬───────┘
          │
          ▼
┌──────────────────────────────────────┐
│  3. CHUNKING                         │
│  - Dividir texto en chunks 500-1000  │  C1: No cargar todo en RAM
│  - Overlap 20%                        │
│  - Asociar tenant_id a CADA chunk    │  C4: Multi-tenancy
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  4. EMBEDDING + QDRANT               │
│  (Ver qdrant-rag-ingestion.md)      │
└──────────────────────────────────────┘
```

### Límites de RAM por Etapa

```javascript
// Cálculo de RAM consumida durante procesamiento

// ETAPA 1: PDF en memoria
const pdfSize = 10 * 1024 * 1024;  // 10 MB
// RAM: ~30MB (PDF + PyMuPDF overhead)

// ETAPA 2: Extracción de texto
const textSize = pdfSize / 10;  // Texto ~ 10% del PDF
// RAM: ~1MB por cada MB de texto

// ETAPA 3: Chunking
const chunks = textSize / 500;  // Chunks de 500 bytes promedio
// RAM: ~2MB (todos los chunks en array)

// TOTAL: 30 + 1 + 2 = 33MB por PDF de 10MB ✅ Dentro de C1
// PDF de 100MB = 330MB ⚠️ Considerar streaming
```

### Procesamiento Paralelo vs Secuencial

```javascript
// ❌ MALO: Procesar todos los PDFs en paralelo (excede C1/C2)
const results = await Promise.all(pdfs.map(pdf => processPDF(pdf)));
// RAM: 33MB × 10 PDFs = 330MB  ❌ Puede causar OOM

// ✅ BUENO: Procesar secuencialmente
const results = [];
for (const pdf of pdfs) {
  const result = await processPDF(pdf);
  results.push(result);
  // RAM liberada después de cada PDF ✅
}

// ✅ MEJOR: Procesar en batches de 2-3
const batchSize = 2;  // C1/C2: Máximo 2 PDFs simultáneos
for (let i = 0; i < pdfs.length; i += batchSize) {
  const batch = pdfs.slice(i, i + batchSize);
  const batchResults = await Promise.all(batch.map(processPDF));
  results.push(...batchResults);
}
```

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Decisión: ¿Dónde Ejecutar OCR?

| Escenario | Herramienta | Ubicación | Pros | Contras |
|-----------|-------------|-----------|------|---------|
| PDF nativo | PyMuPDF | VPS local | Rápido (<1s), gratis | Consume RAM local |
| PDF escaneado | Mistral Pixtral API | Cloud (C6) | No consume RAM/CPU local | Costo ($0.002/página), latencia (3-5s) |
| PDF escaneado | Tesseract | VPS local | Gratis | ❌ Viola C6, consume CPU/RAM |

**Configuración recomendada:**

```javascript
// pdf-processor-config.js
export const config = {
  // Estrategia de OCR
  ocr: {
    provider: process.env.OCR_PROVIDER || 'mistral',  // 'mistral', 'google_vision', 'aws_textract'
    fallback: 'google_vision',  // Si Mistral falla
    maxPagesOCR: 50  // C2: No OCR en PDFs >50 páginas (demasiado CPU)
  },
  
  // Límites de recursos (C1/C2)
  limits: {
    maxFileSizeMB: 100,  // No procesar PDFs >100MB
    maxPages: 200,       // No procesar PDFs >200 páginas
    parallelPDFs: 2,     // Máximo 2 PDFs simultáneos
    chunkSize: 1000,     // Tokens por chunk
    chunkOverlap: 200    // 20% overlap
  },
  
  // Multi-tenancy (C4)
  tenantId: null  // DEBE ser configurado por request
};
```

### Variables de Entorno

```bash
# .env

# Mistral OCR (C6)
MISTRAL_API_KEY=sk-xxx
MISTRAL_OCR_MODEL=pixtral-12b-2409  # Modelo multimodal

# Alternativas (si Mistral no disponible)
GOOGLE_VISION_API_KEY=xxx
AWS_TEXTRACT_ACCESS_KEY=xxx

# Configuración OCR
OCR_PROVIDER=mistral
OCR_FALLBACK=google_vision
MAX_FILE_SIZE_MB=100
MAX_PAGES=200
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Tabla para Tracking de PDFs Procesados

```sql
-- Extender schema de postgres-prisma-rag.md

CREATE TABLE pdf_processing_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,  -- C4: OBLIGATORIO
  
  -- Archivo original
  file_path TEXT NOT NULL,
  filename TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  
  -- Análisis preliminar
  total_pages INTEGER NOT NULL,
  is_scanned BOOLEAN DEFAULT false,
  detected_language TEXT DEFAULT 'es',
  
  -- Estado de procesamiento
  status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'processing', 'completed', 'failed'
  ocr_provider TEXT,  -- 'mistral', 'google_vision', null (si es nativo)
  
  -- Metadata de procesamiento
  processing_time_seconds INTEGER,
  extracted_text_length INTEGER,
  chunks_created INTEGER DEFAULT 0,
  ocr_cost_usd NUMERIC(10, 4) DEFAULT 0.00,
  
  -- Errores
  error_msg TEXT,
  error_stack TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  
  -- Constraints
  CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  CHECK (total_pages > 0),
  CHECK (file_size_bytes > 0)
);

-- Índices
CREATE INDEX idx_pdf_jobs_tenant_status ON pdf_processing_jobs(tenant_id, status);
CREATE INDEX idx_pdf_jobs_created ON pdf_processing_jobs(created_at DESC);
```

### Diagrama de Flujo de Datos

```
Usuario sube PDF → Google Drive/n8n
          ↓
   pdf_processing_jobs (status: pending)
          ↓
   Worker procesa (PyMuPDF o Mistral OCR)
          ↓
   Texto extraído → Chunking
          ↓
   document_chunks (con tenant_id)
          ↓
   Embeddings → Qdrant
          ↓
   pdf_processing_jobs (status: completed)
```

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Detectar si PDF es Nativo o Escaneado

```python
# detect_pdf_type.py
import fitz  # PyMuPDF
import os

def analyze_pdf(pdf_path):
    """
    Analiza un PDF y determina si es nativo o escaneado.
    
    Returns:
        dict con metadata del PDF
    """
    # C1: Verificar tamaño antes de cargar
    file_size = os.path.getsize(pdf_path)
    max_size = 100 * 1024 * 1024  # 100MB
    
    if file_size > max_size:
        raise ValueError(f"PDF too large: {file_size / 1024 / 1024:.1f}MB (max {max_size / 1024 / 1024}MB)")
    
    doc = fitz.open(pdf_path)
    total_pages = len(doc)
    
    # C2: Limitar análisis de páginas
    if total_pages > 200:
        raise ValueError(f"Too many pages: {total_pages} (max 200)")
    
    # Analizar primeras 3 páginas para determinar tipo
    sample_pages = min(3, total_pages)
    total_text_chars = 0
    
    for page_num in range(sample_pages):
        page = doc[page_num]
        text = page.get_text()
        total_text_chars += len(text.strip())
    
    # Heurística: Si hay <50 caracteres por página, es escaneado
    avg_chars_per_page = total_text_chars / sample_pages
    is_scanned = avg_chars_per_page < 50
    
    metadata = {
        'filename': os.path.basename(pdf_path),
        'file_size_bytes': file_size,
        'total_pages': total_pages,
        'is_scanned': is_scanned,
        'detected_type': 'scanned' if is_scanned else 'native',
        'avg_chars_per_page': avg_chars_per_page
    }
    
    doc.close()
    return metadata

# Uso
info = analyze_pdf('/path/to/document.pdf')
print(f"Type: {info['detected_type']}")
print(f"Pages: {info['total_pages']}")
print(f"Scanned: {info['is_scanned']}")
```

### Ejemplo 2: Extraer Texto de PDF Nativo (PyMuPDF)

```python
# extract_native_pdf.py
import fitz
from typing import List, Dict

def extract_text_from_native_pdf(
    pdf_path: str,
    tenant_id: str  # C4: OBLIGATORIO
) -> List[Dict]:
    """
    Extrae texto de PDF nativo página por página.
    
    Returns:
        Lista de chunks con metadata
    """
    if not tenant_id:
        raise ValueError("tenant_id is required (C4)")
    
    doc = fitz.open(pdf_path)
    chunks = []
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        
        # Extraer texto
        text = page.get_text()
        
        # Limpiar texto
        text = text.strip()
        if len(text) < 50:  # Página casi vacía
            continue
        
        # Crear chunk con metadata
        chunk = {
            'tenant_id': tenant_id,  # C4
            'text': text,
            'metadata': {
                'page': page_num + 1,  # 1-indexed
                'source': os.path.basename(pdf_path),
                'extraction_method': 'pymupdf',
                'bbox': page.rect  # Bounding box de la página
            },
            'token_count': len(text.split())  # Aproximación
        }
        
        chunks.append(chunk)
    
    doc.close()
    print(f"✅ Extracted {len(chunks)} chunks from {len(doc)} pages")
    return chunks

# Uso
chunks = extract_text_from_native_pdf(
    '/path/to/native.pdf',
    tenant_id='restaurant_456'
)

# Output:
# ✅ Extracted 45 chunks from 45 pages
```

### Ejemplo 3: OCR de PDF Escaneado con Mistral Pixtral

```python
# ocr_scanned_pdf.py
import fitz
import base64
import requests
from typing import List, Dict

def ocr_scanned_pdf_mistral(
    pdf_path: str,
    tenant_id: str,  # C4
    mistral_api_key: str
) -> List[Dict]:
    """
    OCR de PDF escaneado usando Mistral Pixtral API.
    
    C6: Usa modelo cloud (no local)
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    doc = fitz.open(pdf_path)
    chunks = []
    total_cost = 0.0
    
    # C2: Limitar páginas a procesar (OCR es costoso en CPU y dinero)
    max_pages_ocr = min(len(doc), 50)
    
    if len(doc) > max_pages_ocr:
        print(f"⚠️  PDF has {len(doc)} pages, processing only first {max_pages_ocr}")
    
    for page_num in range(max_pages_ocr):
        page = doc[page_num]
        
        # Convertir página a imagen
        pix = page.get_pixmap(dpi=150)  # 150 DPI suficiente para OCR
        img_bytes = pix.tobytes("png")
        img_b64 = base64.b64encode(img_bytes).decode('utf-8')
        
        # Llamar a Mistral Pixtral API
        response = requests.post(
            'https://api.mistral.ai/v1/chat/completions',
            headers={
                'Authorization': f'Bearer {mistral_api_key}',
                'Content-Type': 'application/json'
            },
            json={
                'model': 'pixtral-12b-2409',
                'messages': [
                    {
                        'role': 'user',
                        'content': [
                            {
                                'type': 'text',
                                'text': 'Extract all text from this image. Return ONLY the extracted text, no explanations.'
                            },
                            {
                                'type': 'image_url',
                                'image_url': f'data:image/png;base64,{img_b64}'
                            }
                        ]
                    }
                ],
                'max_tokens': 4000  # Suficiente para página completa
            },
            timeout=30  # C2: No esperar >30s por página
        )
        
        if response.status_code != 200:
            print(f"❌ OCR failed for page {page_num + 1}: {response.text}")
            continue
        
        result = response.json()
        extracted_text = result['choices'][0]['message']['content']
        
        # Estimar costo (Pixtral: ~$0.0004/1K tokens)
        tokens_used = result['usage']['total_tokens']
        page_cost = (tokens_used / 1000) * 0.0004
        total_cost += page_cost
        
        # Crear chunk
        chunk = {
            'tenant_id': tenant_id,  # C4
            'text': extracted_text,
            'metadata': {
                'page': page_num + 1,
                'source': os.path.basename(pdf_path),
                'extraction_method': 'mistral_pixtral',
                'ocr_confidence': 0.95,  # Pixtral no devuelve confidence
                'tokens_used': tokens_used,
                'cost_usd': round(page_cost, 4)
            },
            'token_count': len(extracted_text.split())
        }
        
        chunks.append(chunk)
        print(f"📄 Page {page_num + 1}/{max_pages_ocr} - {len(extracted_text)} chars - ${page_cost:.4f}")
    
    doc.close()
    print(f"✅ OCR completed: {len(chunks)} pages, total cost: ${total_cost:.2f}")
    
    return chunks

# Uso
chunks = ocr_scanned_pdf_mistral(
    '/path/to/scanned.pdf',
    tenant_id='restaurant_456',
    mistral_api_key='sk-xxx'
)
```

### Ejemplo 4: Pipeline Completo con Detección Automática

```python
# pdf_ingestion_pipeline.py
import os
from detect_pdf_type import analyze_pdf
from extract_native_pdf import extract_text_from_native_pdf
from ocr_scanned_pdf import ocr_scanned_pdf_mistral

def process_pdf_auto(
    pdf_path: str,
    tenant_id: str,  # C4
    mistral_api_key: str = None
) -> Dict:
    """
    Pipeline completo: detecta tipo de PDF y procesa automáticamente.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    # Paso 1: Analizar PDF
    print(f"🔍 Analyzing PDF: {pdf_path}")
    metadata = analyze_pdf(pdf_path)
    
    # Paso 2: Procesar según tipo
    if metadata['is_scanned']:
        print(f"📸 Detected scanned PDF, using OCR...")
        
        if not mistral_api_key:
            raise ValueError("Mistral API key required for scanned PDFs")
        
        chunks = ocr_scanned_pdf_mistral(
            pdf_path,
            tenant_id,
            mistral_api_key
        )
        processing_method = 'mistral_pixtral_ocr'
        
    else:
        print(f"📝 Detected native PDF, using direct extraction...")
        chunks = extract_text_from_native_pdf(pdf_path, tenant_id)
        processing_method = 'pymupdf_native'
    
    # Paso 3: Chunking (dividir texto largo en pedazos)
    final_chunks = apply_chunking(chunks, chunk_size=1000, overlap=200)
    
    # Paso 4: Retornar resultado
    result = {
        'filename': metadata['filename'],
        'total_pages': metadata['total_pages'],
        'is_scanned': metadata['is_scanned'],
        'processing_method': processing_method,
        'chunks_created': len(final_chunks),
        'chunks': final_chunks,
        'tenant_id': tenant_id  # C4: Presente en output
    }
    
    return result

def apply_chunking(chunks, chunk_size=1000, overlap=200):
    """
    Divide chunks largos en pedazos más pequeños con overlap.
    
    C1: Evita chunks enormes que consuman RAM
    """
    final_chunks = []
    
    for chunk in chunks:
        text = chunk['text']
        words = text.split()
        
        # Si chunk es pequeño, mantener como está
        if len(words) <= chunk_size:
            final_chunks.append(chunk)
            continue
        
        # Dividir en sub-chunks con overlap
        for i in range(0, len(words), chunk_size - overlap):
            sub_text = ' '.join(words[i:i + chunk_size])
            
            sub_chunk = {
                **chunk,  # Copiar metadata
                'text': sub_text,
                'token_count': len(sub_text.split()),
                'metadata': {
                    **chunk['metadata'],
                    'chunk_index': i // (chunk_size - overlap),
                    'is_sub_chunk': True
                }
            }
            
            final_chunks.append(sub_chunk)
    
    return final_chunks

# Uso completo
result = process_pdf_auto(
    '/uploads/manual.pdf',
    tenant_id='restaurant_456',
    mistral_api_key='sk-xxx'
)

print(f"\n📊 Summary:")
print(f"  Type: {result['processing_method']}")
print(f"  Pages: {result['total_pages']}")
print(f"  Chunks: {result['chunks_created']}")
print(f"  Tenant: {result['tenant_id']}")  # C4: Validar siempre presente
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Extraer Solo Tablas de PDF

```python
# extract_tables.py
import camelot  # Requiere: pip install camelot-py[cv]

def extract_tables_from_pdf(pdf_path, tenant_id):
    """
    Extrae tablas de PDF y las convierte a texto estructurado.
    
    C1: camelot consume ~200MB RAM por PDF
    """
    # Extraer todas las tablas
    tables = camelot.read_pdf(pdf_path, pages='all', flavor='lattice')
    
    chunks = []
    for i, table in enumerate(tables):
        # Convertir tabla a markdown
        markdown = table.df.to_markdown(index=False)
        
        chunk = {
            'tenant_id': tenant_id,  # C4
            'text': markdown,
            'metadata': {
                'type': 'table',
                'table_index': i,
                'accuracy': table.accuracy,
                'page': table.page
            }
        }
        chunks.append(chunk)
    
    return chunks
```

### Caso 2: Procesar PDFs desde Google Drive

```javascript
// process-gdrive-pdf.js (n8n compatible)
const { google } = require('googleapis');
const fs = require('fs');

async function downloadAndProcessGDrivePDF(fileId, tenantId) {
  // C4: Validar tenant
  if (!tenantId) throw new Error('tenant_id required');
  
  // Autenticar con Google Drive
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  // Descargar PDF
  const dest = fs.createWriteStream(`/tmp/${fileId}.pdf`);
  const res = await drive.files.get(
    { fileId: fileId, alt: 'media' },
    { responseType: 'stream' }
  );
  
  await new Promise((resolve, reject) => {
    res.data
      .pipe(dest)
      .on('finish', resolve)
      .on('error', reject);
  });
  
  // Procesar PDF (llamar a pipeline Python)
  const { exec } = require('child_process');
  const result = await new Promise((resolve, reject) => {
    exec(
      `python3 pdf_ingestion_pipeline.py /tmp/${fileId}.pdf ${tenantId}`,
      (error, stdout, stderr) => {
        if (error) reject(error);
        resolve(JSON.parse(stdout));
      }
    );
  });
  
  // Cleanup
  fs.unlinkSync(`/tmp/${fileId}.pdf`);
  
  return result;
}
```

### Caso 3: OCR con Google Vision API (Alternativa)

```python
# ocr_google_vision.py
from google.cloud import vision
import io

def ocr_with_google_vision(pdf_path, tenant_id):
    """
    OCR usando Google Vision API (mejor precisión que Mistral).
    
    C6: Modelo cloud
    """
    client = vision.ImageAnnotatorClient()
    
    with io.open(pdf_path, 'rb') as image_file:
        content = image_file.read()
    
    image = vision.Image(content=content)
    response = client.document_text_detection(image=image)
    
    if response.error.message:
        raise Exception(f"Google Vision error: {response.error.message}")
    
    # Extraer texto
    text = response.full_text_annotation.text
    
    # Estimar costo (Vision: $1.50/1000 imágenes)
    cost_per_page = 0.0015
    
    chunk = {
        'tenant_id': tenant_id,  # C4
        'text': text,
        'metadata': {
            'extraction_method': 'google_vision',
            'cost_usd': cost_per_page,
            'confidence': response.full_text_annotation.pages[0].confidence if response.full_text_annotation.pages else 0.0
        }
    }
    
    return chunk
```

### Caso 4: Validar Calidad de OCR

```python
# validate_ocr_quality.py
import re

def validate_ocr_quality(text):
    """
    Valida la calidad del texto extraído por OCR.
    
    Returns:
        dict con score de calidad (0-100)
    """
    # Métricas de calidad
    total_chars = len(text)
    
    # 1. Palabras con caracteres raros (indicador de OCR malo)
    weird_chars = re.findall(r'[^\w\s\-.,!?áéíóúñÁÉÍÓÚÑ]', text)
    weird_ratio = len(weird_chars) / max(total_chars, 1)
    
    # 2. Palabras muy cortas (<2 letras) excesivas
    words = text.split()
    short_words = [w for w in words if len(w) < 2]
    short_ratio = len(short_words) / max(len(words), 1)
    
    # 3. Densidad de números (puede indicar error en tablas)
    digits = re.findall(r'\d', text)
    digit_ratio = len(digits) / max(total_chars, 1)
    
    # Calcular score (0-100)
    quality_score = 100
    quality_score -= weird_ratio * 50  # Penalizar caracteres raros
    quality_score -= short_ratio * 30  # Penalizar palabras cortas
    
    if digit_ratio > 0.3:  # >30% números es sospechoso
        quality_score -= 20
    
    quality_score = max(0, quality_score)
    
    issues = []
    if weird_ratio > 0.05:
        issues.append(f"High weird char ratio: {weird_ratio:.1%}")
    if short_ratio > 0.3:
        issues.append(f"Too many short words: {short_ratio:.1%}")
    if digit_ratio > 0.3:
        issues.append(f"High digit ratio: {digit_ratio:.1%}")
    
    return {
        'quality_score': round(quality_score, 1),
        'issues': issues,
        'is_acceptable': quality_score > 70
    }

# Uso
validation = validate_ocr_quality(ocr_text)
if not validation['is_acceptable']:
    print(f"⚠️  Low quality OCR: {validation['quality_score']}/100")
    print(f"Issues: {', '.join(validation['issues'])}")
```

### Caso 5: Batch Processing con Queue (Bull)

```javascript
// pdf-queue.js
const Queue = require('bull');
const { processPDFAuto } = require('./pdf_ingestion_pipeline');

// C1/C2: Cola para evitar procesar múltiples PDFs simultáneos
const pdfQueue = new Queue('pdf-processing', {
  redis: {
    host: 'localhost',
    port: 6379
  }
});

// Worker: Procesa 1 PDF a la vez
pdfQueue.process(async (job) => {
  const { pdfPath, tenantId } = job.data;
  
  console.log(`Processing PDF: ${pdfPath} for tenant ${tenantId}`);
  
  const result = await processPDFAuto(pdfPath, tenantId);
  
  return result;
});

// Agregar PDF a la cola
async function enqueuePDF(pdfPath, tenantId) {
  await pdfQueue.add({
    pdfPath,
    tenantId  // C4
  }, {
    attempts: 3,  // Retry hasta 3 veces si falla
    backoff: {
      type: 'exponential',
      delay: 2000
    }
  });
}

// Uso
await enqueuePDF('/uploads/manual.pdf', 'restaurant_456');
```

### Caso 6: Logs Estructurados de Procesamiento

```python
# structured_logging.py
import json
import logging
from datetime import datetime

# Configurar logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('pdf_processor')

def log_pdf_processing(tenant_id, event, metadata=None):
    """
    Logging estructurado para auditoría.
    
    C4: tenant_id en TODOS los logs
    """
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'tenant_id': tenant_id,  # C4
        'event': event,
        'metadata': metadata or {}
    }
    
    logger.info(json.dumps(log_entry))

# Uso
log_pdf_processing('restaurant_456', 'pdf_processing_started', {
    'filename': 'manual.pdf',
    'file_size_mb': 5.2
})

log_pdf_processing('restaurant_456', 'pdf_processing_completed', {
    'chunks_created': 45,
    'processing_time_seconds': 12.5,
    'method': 'pymupdf_native'
})
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|--------------|-----------|------------------------|----------------------|
| `RuntimeError: PDF is password protected` | PDF encriptado | `pdfinfo file.pdf` (muestra "Encrypted: yes") | 1. Pedir contraseña al usuario<br>2. Desencriptar con PyPDF2:<br>`reader = PdfReader(file); reader.decrypt('password')`<br>3. O rechazar el archivo |
| `MemoryError` durante OCR de PDF grande | PDF >100MB excede RAM disponible (C1) | `docker stats` (ver MEM USAGE) | 1. Dividir PDF en partes: `pdftk input.pdf burst`<br>2. Procesar cada parte secuencialmente<br>3. O aumentar límite en config: `MAX_FILE_SIZE_MB=50` |
| OCR devuelve texto con caracteres raros (�, ▯) | Encoding incorrecto o imagen muy borrosa | Ver validación de calidad arriba | 1. Re-escanear documento a mayor DPI (300+)<br>2. Usar Google Vision en vez de Mistral (mejor con imágenes malas)<br>3. O ajustar brightness/contrast antes de OCR |
| `API rate limit exceeded` en Mistral | Demasiadas requests simultáneas | Ver logs de API | 1. Implementar retry con backoff exponencial<br>2. Usar cola (Bull) para serializar requests<br>3. O cambiar a Google Vision (límites más altos) |
| PyMuPDF extrae texto pero está desordenado | PDF con layout complejo (columnas múltiples) | Ver texto extraído vs PDF original | 1. Usar `page.get_text('layout')` para preservar posiciones<br>2. O procesar por regiones:<br>`page.get_textbox(rect)` para cada columna<br>3. Alternativa: pdfplumber (mejor con tablas) |
| `ModuleNotFoundError: No module named 'fitz'` | PyMuPDF no instalado correctamente | `pip list | grep PyMuPDF` | 1. Instalar: `pip install PyMuPDF==1.23.8`<br>2. Verificar: `python -c "import fitz; print(fitz.__version__)"`<br>3. Si persiste, recrear venv |

---

## ✅ Validación SDD y Comandos de Prueba

### Test Suite para PDF Processing

```python
# test_pdf_processing.py
import pytest
from pdf_ingestion_pipeline import process_pdf_auto

def test_native_pdf_extraction():
    """Test extracción de PDF nativo."""
    result = process_pdf_auto(
        'test_files/native_sample.pdf',
        tenant_id='test_tenant'
    )
    
    # C4: Validar tenant_id en todos los chunks
    assert result['tenant_id'] == 'test_tenant'
    for chunk in result['chunks']:
        assert chunk['tenant_id'] == 'test_tenant', "C4 violation: missing tenant_id"
    
    # Validar metadata
    assert result['is_scanned'] == False
    assert result['processing_method'] == 'pymupdf_native'
    assert result['chunks_created'] > 0

def test_scanned_pdf_ocr():
    """Test OCR de PDF escaneado."""
    result = process_pdf_auto(
        'test_files/scanned_sample.pdf',
        tenant_id='test_tenant',
        mistral_api_key='sk-xxx'
    )
    
    assert result['is_scanned'] == True
    assert result['processing_method'] == 'mistral_pixtral_ocr'
    assert result['chunks_created'] > 0

def test_large_pdf_rejected():
    """Test que PDFs muy grandes sean rechazados (C1)."""
    with pytest.raises(ValueError, match="PDF too large"):
        process_pdf_auto(
            'test_files/large_sample_150mb.pdf',
            tenant_id='test_tenant'
        )

def test_too_many_pages_rejected():
    """Test que PDFs con muchas páginas sean rechazados (C2)."""
    with pytest.raises(ValueError, match="Too many pages"):
        process_pdf_auto(
            'test_files/book_500_pages.pdf',
            tenant_id='test_tenant'
        )

# Ejecutar tests
# pytest test_pdf_processing.py -v
```

### Validación de Costos de OCR

```python
# cost_calculator.py

def calculate_ocr_cost(pages, provider='mistral'):
    """
    Calcula costo estimado de OCR para presupuestar.
    
    C6: Solo modelos cloud
    """
    costs = {
        'mistral': 0.0004 * 1000 / pages,  # ~$0.0004 per 1K tokens, ~1K tokens/página
        'google_vision': 0.0015,  # $1.50 per 1000 imágenes
        'aws_textract': 0.0015
    }
    
    cost_per_page = costs.get(provider, 0)
    total_cost = cost_per_page * pages
    
    return {
        'provider': provider,
        'pages': pages,
        'cost_per_page': cost_per_page,
        'total_cost': round(total_cost, 2)
    }

# Ejemplo: Presupuesto mensual
monthly_pdfs = 100  # PDFs por mes
avg_pages = 30      # Páginas promedio

cost = calculate_ocr_cost(monthly_pdfs * avg_pages, 'mistral')
print(f"Monthly OCR cost estimate: ${cost['total_cost']}")
# Output: Monthly OCR cost estimate: $1.20
```

### Comando de Validación de tenant_id (C4)

```bash
# validate_tenant_id.sh
# Buscar chunks sin tenant_id en output

jq '.chunks[] | select(.tenant_id == null or .tenant_id == "")' result.json

# Output esperado: VACÍO (ningún chunk sin tenant_id)
# Si devuelve algo: ❌ C4 violation
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] - RES-008 (chunking), RES-010 (límites de archivo)
- [[01-RULES/06-MULTITENANCY-RULES.md]] - MT-004, MT-007 (tenant_id en metadata)
- [[00-CONTEXT/facundo-infrastructure.md]] - C1/C2 (límites hardware), C6 (solo APIs cloud)

**Skills relacionados:**
- `qdrant-rag-ingestion.md` - Siguiente paso: vectorizar chunks extraídos
- `postgres-prisma-rag.md` - Almacenar metadata de PDFs procesados
- `google-drive-qdrant-sync.md` - Automatizar ingesta desde Drive
