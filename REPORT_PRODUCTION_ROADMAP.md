# Production Readiness & Roadmap

## 1. Interview Readiness Assessment
The candidate is ready for a Senior technical interview.
- **Probable Question**: "How do you optimize this for real-time camera streaming?"
- **Recommended Focus**: "I would move the OCR processing to an Isolate to prevent UI thread blockage and implement a frame-skipping logic."

## 2. Overengineering Warnings
- **DI Container**: While `GetIt` is great, for an assignment of this size, it's at the limit of necessity.
- **Complex Scoring**: The scoring system is highly impressive but adds maintenance overhead compared to simpler regex for a junior role.

## 3. Future Improvements (Roadmap)
1. **Image Pre-processing**: Implement the TODOs in `ImageService` for grayscale and contrast enhancement to improve ML Kit performance on low-light scans.
2. **Persistence**: Add a local database (Hive/Isar) to store scan history securely.
3. **Multi-Step Parsing**: For cards where the expiry is on the back, implement a "Scan Back Side" flow.
4. **Isolate Processing**: Offload the `TextCleaner` and `Regex` heavy lifting to a background isolate for smoother UI interaction on low-end devices.
