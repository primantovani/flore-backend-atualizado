package br.com.fiap.flore.controller;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiFlowTests {

    @Autowired
    private MockMvc mvc;

    private String cadastrar(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Teste\",\"email\":\"" + email + "\",\"password\":\"senha123\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.email").value(email))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.token");
    }

    @Test
    void cadastroDevolveTokenELoginFunciona() throws Exception {
        cadastrar("login@flore.test");

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"login@flore.test\",\"password\":\"senha123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    void loginComSenhaErradaNaoDevolveToken() throws Exception {
        cadastrar("senha@flore.test");

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"senha@flore.test\",\"password\":\"errada99\"}"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void cadastroRecusaSenhaCurta() throws Exception {
        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Teste\",\"email\":\"curta@flore.test\",\"password\":\"123\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void criarPecaExigeToken() throws Exception {
        mvc.perform(post("/api/closet")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Saia\",\"category\":\"saia\",\"price\":50}"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void pecaCriadaApareceNoMarketplacePublico() throws Exception {
        String token = cadastrar("closet@flore.test");

        String body = mvc.perform(post("/api/closet")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Vestido floral\",\"category\":\"vestido\",\"price\":120.5,\"size\":\"M\"}"))
                .andExpect(status().is2xxSuccessful())
                .andExpect(jsonPath("$.status").value("available"))
                .andReturn().getResponse().getContentAsString();
        Integer id = JsonPath.read(body, "$.id");

        mvc.perform(get("/api/closet"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(id)));
    }
}
