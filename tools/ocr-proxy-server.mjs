#!/usr/bin/env node

import { createServer } from "node:http";

const port = Number(process.env.PORT ?? "8787");
const anthropicAPIKey = process.env.ANTHROPIC_API_KEY?.trim() ?? "";
const anthropicModel = process.env.ANTHROPIC_MODEL?.trim() || "claude-opus-4-5";

const mockDictionary = new Map([
  ["腕", { reading: "うで", meaning: "팔" }],
  ["機会", { reading: "きかい", meaning: "기회" }],
  ["勉強", { reading: "べんきょう", meaning: "공부" }],
  ["漢字", { reading: "かんじ", meaning: "한자" }],
]);

function sendJSON(response, statusCode, payload) {
  response.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
}

function readJSON(request) {
  return new Promise((resolve, reject) => {
    let body = "";

    request.setEncoding("utf8");
    request.on("data", chunk => {
      body += chunk;
    });
    request.on("end", () => {
      if (!body.trim()) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(body));
      } catch (error) {
        reject(error);
      }
    });
    request.on("error", reject);
  });
}

function normalizeWords(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map(item => (typeof item === "string" ? item.trim() : ""))
    .filter(Boolean);
}

function buildWordPrompt(words) {
  return {
    system: [
      "You are a Japanese vocabulary assistant.",
      "For each Japanese word provided, give its reading (furigana) and Korean meaning.",
      'Output ONLY valid JSON in the format {"cards":[{"kanji":"腕","reading":"うで","meaning":"팔"}]}.',
    ].join(" "),
    messages: [
      {
        role: "user",
        content: `다음 단어들의 읽기와 뜻을 알려주세요:\n${words.join("\n")}`,
      },
    ],
  };
}

async function relayToAnthropic(payload) {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": anthropicAPIKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: anthropicModel,
      max_tokens: 2048,
      ...payload,
    }),
  });

  const data = await response.json().catch(async () => {
    const text = await response.text();
    throw new Error(text || `HTTP ${response.status}`);
  });

  if (!response.ok) {
    const detail = data?.error?.message || data?.error || `HTTP ${response.status}`;
    throw new Error(detail);
  }

  return {
    id: data.id ?? "relay-response",
    type: data.type ?? "message",
    role: data.role ?? "assistant",
    model: data.model ?? anthropicModel,
    content: Array.isArray(data.content) ? data.content : [],
  };
}

function buildMockCards(words) {
  if (words.length > 0) {
    return words.map((word, index) => {
      const known = mockDictionary.get(word);
      return {
        kanji: word,
        reading: known?.reading ?? `mock-reading-${index + 1}`,
        meaning: known?.meaning ?? `mock-meaning-${index + 1}`,
      };
    });
  }

  return [];
}

const server = createServer(async (request, response) => {
  if (request.method === "GET" && request.url === "/health") {
    sendJSON(response, 200, { ok: true, mode: anthropicAPIKey ? "relay" : "mock" });
    return;
  }

  if (request.method !== "POST" || request.url !== "/api/ocr") {
    sendJSON(response, 404, { error: "Not found" });
    return;
  }

  try {
    const body = await readJSON(request);
    const words = normalizeWords(body.words);

    if (words.length === 0) {
      sendJSON(response, 400, {
        error: "OCR proxy is text-only. Provide a non-empty words array.",
      });
      return;
    }

    if (anthropicAPIKey) {
      const anthropicPayload = buildWordPrompt(words);
      const relayResponse = await relayToAnthropic(anthropicPayload);
      sendJSON(response, 200, relayResponse);
      return;
    }

    const cards = buildMockCards(words);
    sendJSON(response, 200, {
      id: "mock-ocr-response",
      type: "message",
      role: "assistant",
      model: "mock-ocr-proxy",
      content: [
        {
          type: "text",
          text: JSON.stringify({ cards }),
        },
      ],
    });
  } catch (error) {
    sendJSON(response, 500, {
      error: error instanceof Error ? error.message : "Unknown proxy error",
    });
  }
});

server.listen(port, "127.0.0.1", () => {
  const mode = anthropicAPIKey ? "relay" : "mock";
  console.log(`OCR proxy stub listening on http://127.0.0.1:${port} (${mode})`);
});
