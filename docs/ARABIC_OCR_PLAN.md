# Arabic OCR plan

Status: **not implemented**. The shipping scanner uses Google ML Kit Latin text recognition only (`TextRecognitionScript.latin` in `lib/features/receipts/services/ocr_service.dart`). That model does not recognize Arabic script. The app tells the user this on the scan screen. Do not treat a Latin result, or an empty result, as an Arabic transcription.

## What was checked

- `google_mlkit_text_recognition` 0.15 exposes script enums such as Latin, Chinese, Devanagari, Japanese, and Korean. It does not ship an Arabic recognizer in this project.
- ProGuard keep rules do not add a language. They only keep Latin ML Kit classes from being stripped when R8 is enabled.
- No Edge Function currently accepts receipt images for OCR.

## A supported path

1. Keep Latin recognition on the device for French and English receipts.
2. Add a separate action, “Recognize Arabic receipt”, that uploads the image only after the user confirms, to a private Storage path `receipts/{auth.uid()}/{operationId}.jpg`.
3. Run OCR in a new Edge Function that:
   - requires `auth.getUser()` and rejects the anon key;
   - checks the object path starts with that user id;
   - calls a server-side OCR provider that documents Arabic support (for example Google Cloud Vision with Arabic language hints, or an equivalent);
   - keeps the provider key in Edge Function secrets, never in Flutter or `.env` assets;
   - returns text only to the caller and does not store another user’s image.
4. Feed that text through the same amount parser and confirmation screen. The user still confirms before `create_transaction`.
5. Test with photographed Arabic receipts on a device. Until those tests pass, the UI must keep saying Arabic is not recognized locally.

## What not to do

- Do not switch the Latin recognizer to another script enum and claim Arabic works.
- Do not send receipt images to a third party from the phone with an API key embedded in the app.
- Do not disable Storage RLS to “make the upload easier”.
