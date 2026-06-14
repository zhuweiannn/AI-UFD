#include <jni.h>

// Public JNI shell: native camera, inference, ROI, and recording implementations are omitted.

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNI_OnUnload(JavaVM* vm, void* reserved) {
}

extern "C"
JNIEXPORT jintArray JNICALL
Java_com_example_liquid_1detect_inference_YOLO_listSupportedResolutions(JNIEnv* env, jobject thiz, jint facing) {
    // ... native implementation omitted from public package.
    return nullptr;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setPreferredCaptureProfile(JNIEnv* env, jobject thiz, jint w, jint h, jint target_fps) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jintArray JNICALL
Java_com_example_liquid_1detect_inference_YOLO_getAppliedCaptureProfile(JNIEnv* env, jobject thiz) {
    // ... native implementation omitted from public package.
    return nullptr;
}

extern "C"
JNIEXPORT jintArray JNICALL
Java_com_example_liquid_1detect_inference_YOLO_getAppliedRecordingProfile(JNIEnv* env, jobject thiz) {
    // ... native implementation omitted from public package.
    return nullptr;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_startRecording(JNIEnv* env, jobject thiz, jint output_fd) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_stopRecording(JNIEnv *env, jobject thiz) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_nativeLoadModel(JNIEnv *env, jobject thiz, jobject assetManager, jstring task_name, jstring model_basename, jint target_size, jint cpugpu) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_openCamera(JNIEnv *env, jobject thiz, jint facing) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_closeCamera(JNIEnv *env, jobject thiz) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setOutputWindow(JNIEnv *env, jobject thiz, jobject surface) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_clearLastOutputFrameCache(JNIEnv *env, jobject thiz) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_processNV21Frame(JNIEnv* env, jobject thiz, jbyteArray nv21Array, jint width, jint height, jlong pts_ns, jint rotate_deg) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setFilePreviewRenderCadence(JNIEnv* env, jobject thiz, jint render_every_n_frames) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setFilePreviewRenderIntervalMs(JNIEnv* env, jobject thiz, jint interval_ms) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setCameraPreviewInferenceEnabled(JNIEnv* env, jobject thiz, jboolean enabled) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setCameraPreviewInferenceIntervalMs(JNIEnv* env, jobject thiz, jint interval_ms) {
    // ... native implementation omitted from public package.
    return JNI_FALSE;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setDetectionsListener(JNIEnv* env, jobject thiz, jobject listener) {
    // ... native callback wiring omitted from public package.
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setRenderResultsListener(JNIEnv* env, jobject thiz, jobject listener) {
    // ... native callback wiring omitted from public package.
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_liquid_1detect_inference_YOLO_setFrameListener(JNIEnv* env, jobject thiz, jobject listener) {
    // ... native callback wiring omitted from public package.
}
