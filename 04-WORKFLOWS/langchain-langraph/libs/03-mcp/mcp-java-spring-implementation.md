---
artifact_id: "mcp-java-spring-implementation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-java-spring-implementation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-java-spring-implementation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-java-spring-v1.0.0"
generated_at: "2026-05-25T02:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain4j-integration", "deploy-kubernetes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ☕ MCP Java/Spring Implementation – Servidores e Clientes com LangChain4j

> **Contrato modular**: Guia completo para implementar servidores e clientes MCP usando Spring Boot 3.3+ e LangChain4j, incluindo ferramentas, recursos, transporte stdio/HTTP e integração com IA.

---

## 🎯 Propósito
Habilitar o ecossistema MANTIS a construir e consumir servidores MCP no ambiente Java/Spring, aproveitando a tipagem forte e o ecossistema empresarial.

## 📋 Especificação (SDD)
- **Entradas**: Serviços Spring, configurações MCP.
- **Saídas**: Servidor/cliente MCP funcional.
- **Side Effects**: Processos stdio ou servlets HTTP.
- **Constraints Aplicáveis**: C1 (tipos e contratos), C3 (segurança), C5 (estrutura), C7 (resiliência), C8 (logs).
- **Dependências**: `spring-ai-starter-mcp-server`, `spring-ai-starter-mcp-client`, `langchain4j`.

---

## 🛡️ Bootstrap (C3+C8)
```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class WeatherService {
    // usando @Tool para expor ferramentas
}
```

### 1. Dependências Maven
```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-mcp-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-mcp-client</artifactId>
</dependency>
```

### 2. Servidor com @Tool e @Service
```java
@Service
public class WeatherService {
    private final RestClient restClient;

    public WeatherService() {
        this.restClient = RestClient.builder()
            .baseUrl("https://api.weather.gov")
            .defaultHeader("Accept", "application/geo+json")
            .defaultHeader("User-Agent", "WeatherApp/1.0")
            .build();
    }

    @Tool(description = "Get weather forecast for a location")
    public String getWeatherForecastByLocation(
            @ToolParam(description = "Latitude coordinate") double latitude,
            @ToolParam(description = "Longitude coordinate") double longitude) {
        log.info("Buscando previsão para {}, {}", latitude, longitude);
        // implementação...
        return "Previsão: ensolarado";
    }

    @Tool(description = "Get weather alerts for a US state")
    public String getAlerts(@ToolParam(description = "Two-letter US state code") String state) {
        // ...
        return "Nenhum alerta ativo.";
    }
}
```

### 3. Configuração do Servidor Stdio
```java
@SpringBootApplication
public class McpServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(McpServerApplication.class, args);
    }

    @Bean
    public ToolCallbackProvider weatherTools(WeatherService weatherService) {
        return MethodToolCallbackProvider.builder().toolObjects(weatherService).build();
    }
}
```
Propriedade: `spring.ai.mcp.server.stdio=true`

### 4. Cliente MCP
```java
@Configuration
public class McpClientConfig {
    @Bean
    public List<McpClient> mcpClients() {
        var stdioParams = ServerParameters.builder("java")
            .args("-jar", "/path/to/server.jar")
            .build();
        var transport = new StdioClientTransport(stdioParams);
        var client = McpClient.sync(transport).build();
        client.initialize();
        return List.of(client);
    }
}
```

### 5. Integração com LangChain4j AI Service
```java
interface Assistant {
    String chat(String message);
}

@Bean
public Assistant assistant(ChatModel chatModel, List<McpClient> mcpClients) {
    var toolProvider = McpToolProvider.builder()
        .mcpClients(mcpClients)
        .failIfOneServerFails(false)
        .filter((client, tool) -> !tool.name().startsWith("admin_"))
        .build();

    return AiServices.builder(Assistant.class)
        .chatModel(chatModel)
        .toolProvider(toolProvider)
        .build();
}
```

### 6. Filtragem e Segurança
```java
.filter((client, tool) -> {
    // Apenas ferramentas permitidas para o tenant atual
    String tenant = TenantContextHolder.getTenant();
    return tool.name().startsWith(tenant + "_");
})
```

---

## 🧪 Testes Unitários (TDD)
```java
@SpringBootTest
class WeatherServiceTest {
    @Autowired
    private WeatherService service;

    @Test
    void testForecast() {
        String result = service.getWeatherForecastByLocation(47.6062, -122.3321);
        assertNotNull(result);
    }
}
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-java-spring-implementation.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-core-concepts.md]]
- [[deploy-kubernetes.md]]
