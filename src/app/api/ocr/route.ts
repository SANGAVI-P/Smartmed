import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { fileData, mimeType, fileName } = await req.json();

    if (!fileData || !mimeType) {
      return NextResponse.json({ error: 'Missing fileData or mimeType' }, { status: 400 });
    }

    // Try server env key first, then header key
    let apiKey = process.env.GEMINI_API_KEY || process.env.NEXT_PUBLIC_GEMINI_API_KEY;
    if (!apiKey) {
      const authHeader = req.headers.get('Authorization') || req.headers.get('x-api-key');
      if (authHeader) {
        apiKey = authHeader.replace('Bearer ', '').trim();
      }
    }

    if (!apiKey) {
      const nameLower = (fileName || '').toLowerCase();
      if (nameLower.includes('lisinopril')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: CARDIOVASCULAR CARE\nDATE: 2026-08-21\n℞ Lisinopril 10mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet daily in the morning for hypertension.",
          medicines: [
            {
              name: "Lisinopril",
              strength: "10 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: false,
              timing: "before_food",
              duration: "30 days",
              confidence: 95
            }
          ],
          confidence: 95,
          isMock: true
        });
      } else if (nameLower.includes('metformin')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: ENDOCRINE HEALTH CARE\nDATE: 2026-08-21\n℞ Metformin 500mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet twice daily with meals.",
          medicines: [
            {
              name: "Metformin",
              strength: "500 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "15 days",
              confidence: 95
            }
          ],
          confidence: 95,
          isMock: true
        });
      } else if (nameLower.includes('atorvastatin')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: LIPID CLINIC\nDATE: 2026-08-21\n℞ Atorvastatin 20mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet daily at bedtime.",
          medicines: [
            {
              name: "Atorvastatin",
              strength: "20 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "30 days",
              confidence: 95
            }
          ],
          confidence: 95,
          isMock: true
        });
      } else if (nameLower.includes('eliquis')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: CARDIOLOGY DIVISION\nDATE: 2026-08-21\n℞ Eliquis 5mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet twice daily.",
          medicines: [
            {
              name: "Eliquis",
              strength: "5 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "15 days",
              confidence: 95
            }
          ],
          confidence: 95,
          isMock: true
        });
      } else if (nameLower.includes('toothpaste')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: DENTAL TOOTHPASTE\nDATE: 2026-08-21\n℞ Toothpaste (Oralhealth)\nDisp: #30 • Refills: 3\nSig / Directions:\nApply to teeth morning & night after food.",
          medicines: [
            {
              name: "Toothpaste",
              strength: "Not detected",
              dosage: "Apply to teeth",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "30 days",
              confidence: 95
            }
          ],
          confidence: 95,
          isMock: true
        });
      } else if (nameLower.includes('unclear') || nameLower.includes('blurry')) {
        return NextResponse.json({
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: GENERAL CLINIC\nDATE: 2026-08-21\n℞ P...etamol 500mg\nDisp: #30 • Refills: 3\nSig / Directions:\nT... 1 tab... pain [ILLEGIBLE]",
          medicines: [],
          confidence: 30,
          isMock: true
        });
      } else {
        return NextResponse.json({
          rawText: "Paracetamol - 1\nDistrin - 1\nLoperamide - 1\nNight Before Food",
          medicines: [
            {
              name: "Paracetamol",
              strength: "500 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "7 days",
              confidence: 98
            },
            {
              name: "Distrin",
              strength: "10 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "7 days",
              confidence: 95
            },
            {
              name: "Loperamide",
              strength: "2 mg",
              dosage: "1 Capsule",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "5 days",
              confidence: 98
            }
          ],
          confidence: 95,
          isMock: true
        });
      }
    }

    const prompt = `Extract all medicine information from this prescription image or PDF. 
You must output a valid JSON object matching the following structure:
{
  "rawText": "The complete raw text extracted from the document",
  "medicines": [
    {
      "name": "Extracted medicine name (leave empty if unrecognizable)",
      "strength": "e.g. 500 mg, 10 mg (leave empty if not found)",
      "dosage": "e.g. 1 Tablet, 2 Capsules, 1 Inhalation (leave empty if not found)",
      "morning": true/false,
      "afternoon": true/false,
      "night": true/false,
      "timing": "before_food" or "after_food" (default to "after_food" if not specified)",
      "duration": "e.g. 5 days, 30 days (leave empty if not found)",
      "confidence": 0-100 (your confidence in extracting this specific medicine)
    }
  ],
  "confidence": 0-100 (overall confidence of prescription scan/readability)
}

Do not guess any fields that are not present. If a field cannot be read, leave it blank or mark it as "Not detected". If the image is blurry, corrupted, or not a medical prescription, return an empty medicines list and confidence score below 50.`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: mimeType,
                  data: fileData,
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return NextResponse.json({ error: 'Gemini API request failed', details: errorText }, { status: response.status });
    }

    const data = await response.json();
    const textResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!textResponse) {
      return NextResponse.json({ error: 'Empty response from Gemini' }, { status: 500 });
    }

    const parsedResult = JSON.parse(textResponse);
    return NextResponse.json(parsedResult);
  } catch (error: any) {
    console.error('OCR Route Error:', error);
    return NextResponse.json({ error: 'Internal Server Error', message: error.message }, { status: 500 });
  }
}
