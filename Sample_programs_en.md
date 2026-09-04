# Cvitek / CVI-TDL Sample Programs Guide for Milk-V Duo S

This document details the functionality, structure, and usage of the pre-compiled sample binaries located in `/usr/share/cvitek/samples/` on the **Milk-V Duo S** (SOPHGO SG2000).

These applications demonstrate the capabilities of the hardware **TPU / NPU** (AI inference engine) and the **IVE / VPSS** (hardware video and image processing engines).

---

## 🛠️ 1. TPU Utilities & Benchmarks

Tools for model inspection, performance profiling, and stress testing.

| Binary | Description |
| :--- | :--- |
| `cvimodel_tool` | Inspects `.cvimodel` architecture, layers, and metadata. |
| `model_runner` | Loads a `.cvimodel` and executes a simple test inference. |
| `multi_model_tester` | Tests concurrent or sequential multi-model execution. |
| `multi_thread_tester` | Benchmarks multi-threaded inference performance and stability. |
| `stress_tester` | Conducts long-running load and stress tests on the TPU. |
| `mat2npz` / `npz2mat` / `npy2mat` | Utilities to convert between NumPy arrays (`.npy`/`.npz`) and C binary matrices (`.mat`). |

---

## 🖼️ 2. Static Image AI Inference (`sample_img_*` / `sample_yolo*`)

These binaries accept a `.cvimodel` file and an input image (JPEG/PNG), run inference on the TPU, and save an annotated output image.

### Face & Human Analytics
* **`sample_img_face_det`**: Face detection.
* **`sample_img_face_recognition`**: Face recognition and identification.
* **`sample_img_face_landmarker`**: Facial landmark extraction.
* **`sample_img_face_attribute_cls`**: Facial attribute classification (age, gender, expression).
* **`sample_img_face_liveness`**: Face liveness detection (anti-spoofing).
* **`sample_img_face_mask`**: Surgical mask detection.
* **`sample_img_face_quality`**: Face image quality assessment.
* **`sample_img_pose`**: Human body pose estimation (2D keypoints).
* **`sample_img_fatigue_eye` / `sample_img_fatigue_yawn`**: Driver fatigue detection (eye closure, yawning).

### Object Detection & Segmentation (YOLO & Vision)
* **`sample_yolov5` / `sample_yolov6` / `sample_yolov7` / `sample_yolov8` / `sample_yolov10` / `sample_yolov11` / `sample_yolox`**: General object detection across various YOLO releases.
* **`sample_yolov8_roi` / `sample_img_detection_roi`**: Region of Interest (ROI) object detection.
* **`sample_yolo_world_v2`**: Open-vocabulary object detection.
* **`sample_ppyoloe`**: PP-YOLOE object detection model.
* **`sample_img_yolov8_seg`**: Instance segmentation with YOLOv8.
* **`sample_img_topformer_seg`**: Real-time semantic segmentation using TopFormer.

### Hands, License Plates & ADAS
* **`sample_img_hand_det`**: Hand detection.
* **`sample_img_hand_keypoint`**: Hand keypoint detection / skeleton tracking.
* **`sample_img_hand_cls`**: Hand gesture classification.
* **`sample_img_lpd_lpr`**: License Plate Detection and Recognition (ALPR).
* **`sample_img_lpd_lpr_keypoint`**: License plate corner/keypoint detection.
* **`sample_img_lane_det`**: Lane boundary detection for ADAS.

### Multimodal & Audio
* **`sample_blip_cap` / `sample_blip_itm` / `sample_blip_vqa`**: Image captioning, image-text matching, and visual question answering (BLIP).
* **`sample_audio_cls` / `sample_aud_cls_read` / `sample_aud_order`**: Audio classification and keyword spotting.

---

## 📹 3. Real-Time Camera Stream Processing (`sample_vi_*` & `sample_stream_*`)

These demos interface directly with the **VI** (Video Input) subsystem to process live camera feeds (MIPI / USB) with hardware acceleration.

| Binary | Description |
| :--- | :--- |
| `sample_vi_od` | Real-time live object detection. |
| `sample_vi_fd` | Real-time live face detection. |
| `sample_vi_face_recog` | Real-time live face recognition. |
| `sample_vi_pose` | Real-time human pose estimation. |
| `sample_vi_occ` | Camera occlusion detection. |
| `sample_stream_hardhat` | Safety helmet / hardhat detection stream. |
| `sample_stream_personvehicle_cross` | Virtual tripwire / boundary crossing detection (pedestrians & vehicles). |
| `sample_stream_consumer_counting` | Real-time people counting stream. |

---

## ⚡ 4. Hardware Image Processing IVE (`test_*` & `sample_*`)

Low-level applications testing the **IVE / VPSS** hardware image acceleration engine independently of the neural network TPU.

* **Filtering & Transformations**: `test_resize_c`, `test_sobel_grad_c`, `test_histEq_c`, `test_filter_c`, `test_csc_c` (color space conversion).
* **Arithmetic & Logic**: `sample_add`, `sample_sub`, `sample_and`, `sample_or`, `sample_xor`, `sample_alpha_blend`.
* **Morphology & Feature Extraction**: `sample_dilate`, `sample_morph`, `sample_hog`, `sample_lbp`, `sample_integral_image`.

---

## 🚀 Quick Start & Usage

### 1. View binary syntax
Run any binary without parameters to view required arguments:
```bash
/usr/share/cvitek/samples/sample_img_face_det
