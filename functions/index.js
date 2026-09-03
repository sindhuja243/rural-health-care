const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Anthropic = require("@anthropic-ai/sdk");

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Define the Anthropic API Key secret securely in Firebase Functions parameters
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

/**
 * Callable Firebase Cloud Function: analyzeSymptoms
 * 
 * Triage Assistant for rural healthcare:
 * - Accepts user symptoms in Telugu, Hindi, or English.
 * - Calls Anthropic Claude API (model: "claude-sonnet-4-6") with secret key.
 * - Enforces safety-critical guidelines: errs toward "high" severity if symptoms are severe or uncertain.
 * - Returns pure structured JSON: { severity, possibleCondition, remedy }
 */
exports.analyzeSymptoms = onCall(
  {
    secrets: [anthropicApiKey],
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    // 1. Validate Input
    const symptomsText = request.data?.symptomsText || request.data?.symptoms;
    if (!symptomsText || typeof symptomsText !== "string" || symptomsText.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Please provide a valid description of symptoms."
      );
    }

    const apiKey = anthropicApiKey.value() || process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      console.error("Missing ANTHROPIC_API_KEY secret in Firebase Functions environment.");
      throw new HttpsError(
        "failed-precondition",
        "AI Triage service is not yet configured with the required API secret."
      );
    }

    const anthropic = new Anthropic({
      apiKey: apiKey,
    });

    // 2. Safety-Critical System Prompt
    const systemPrompt = `You are a basic triage assistant for a rural health app called "Gramin Seva Health" serving rural Indian communities.
Your role is triage classification, NOT a formal medical diagnosis.

CRITICAL SAFETY RULES:
1. You MUST always err toward "high" severity if there is ANY doubt or if symptoms sound serious (including but not limited to: chest pain, pressure or tightness, breathing difficulty, shortness of breath, high or persistent fever, pregnancy pain or complications, severe injury, loss of consciousness, stroke symptoms, uncontrolled bleeding, severe abdominal pain, sudden severe weakness).
2. "low" severity is STRICTLY reserved for mild, self-limiting, minor ailments such as common seasonal cold, mild dry cough, minor fatigue, or mild indigestion without red-flag symptoms.
3. You must understand symptoms provided in Telugu (తెలుగు), Hindi (हिंदी), or English.
4. If severity is "low", the remedy MUST be provided as a simple, safe home remedy written in both Telugu and English (e.g., "తులసి మరియు అల్లం టీ తాగండి / Drink warm tulsi ginger water, rest well").
5. If severity is "high", the remedy field MUST be null.
6. You must respond with ONLY valid raw JSON in the exact shape below. Do NOT output markdown code blocks (no \`\`\`json), no introductory text, no explanations, no trailing text.

Exact JSON shape:
{"severity": "low" or "high", "possibleCondition": "short name of the likely condition", "remedy": "a short simple home remedy in Telugu and English, only if severity is low, else null"}`;

    const userPrompt = `Patient symptoms: "${symptomsText.trim()}"

Analyze these symptoms and return the exact JSON triage object.`;

    try {
      console.log(`Analyzing symptoms: "${symptomsText.substring(0, 80)}..."`);

      const response = await anthropic.messages.create({
        model: "claude-sonnet-4-6",
        max_tokens: 400,
        temperature: 0.1,
        system: systemPrompt,
        messages: [
          {
            role: "user",
            content: userPrompt,
          },
        ],
      });

      const responseContent = response.content?.[0]?.text?.trim() || "";
      console.log("Anthropic Claude response:", responseContent);

      // 3. Safe JSON extraction & parsing (handling optional markdown wrappers)
      let cleanedJson = responseContent;
      if (cleanedJson.includes("```json")) {
        cleanedJson = cleanedJson.replace(/```json/gi, "").replace(/```/g, "").trim();
      } else if (cleanedJson.includes("```")) {
        cleanedJson = cleanedJson.replace(/```/g, "").trim();
      }

      // Locate outermost JSON object braces
      const firstBrace = cleanedJson.indexOf("{");
      const lastBrace = cleanedJson.lastIndexOf("}");
      if (firstBrace !== -1 && lastBrace !== -1) {
        cleanedJson = cleanedJson.substring(firstBrace, lastBrace + 1);
      }

      const parsedResult = JSON.parse(cleanedJson);

      // Validate required JSON fields
      const severity = parsedResult.severity === "low" ? "low" : "high";
      const possibleCondition = parsedResult.possibleCondition || (severity === "high" ? "Urgent Medical Evaluation Required" : "Mild Symptom");
      const remedy = severity === "low" ? (parsedResult.remedy || "Drink warm water, take rest, and monitor symptoms. / గోరువెచ్చని నీరు త్రాగి విశ్రాంతి తీసుకోండి.") : null;

      const finalResult = {
        severity: severity,
        possibleCondition: possibleCondition,
        remedy: remedy,
      };

      console.log("Parsed triage result:", finalResult);
      return finalResult;
    } catch (err) {
      console.error("Error invoking Claude API or parsing response:", err);
      throw new HttpsError(
        "internal",
        "Failed to analyze symptoms through AI triage service. Please try again or visit your nearest PHC."
      );
    }
  }
);
