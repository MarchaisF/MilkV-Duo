# Pre-trained Models (.cvimodel) Catalog - Milk-V Duo S (CV181X)

This guide details the purpose of the pre-installed AI models found under `/usr/share/cvitek/models/` on the Milk-V Duo S development board. These models are optimized for the onboard NPU/TPU (`INT8`, `MIX`, and `BF16` formats) using the **CVI-TDL** library / **Cvitek SDK**.

---

## 🎯 General Object Detection (COCO 80 Classes)
Models trained on the COCO dataset for general multi-object detection (people, vehicles, animals, everyday objects).

* **`yolov5s_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov5m_...`**: YOLOv5 in *small* (fast) and *medium* (more accurate) variants.
* **`yolov6n_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov6s_...`**: YOLOv6 in *nano* and *small* variants.
* **`yolov7_tiny_det_coco80_640_640_INT8_cv181x.cvimodel`**: Ultra-lightweight YOLOv7 tailored for embedded systems.
* **`yolov8n_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov8s_...`**: YOLOv8 in *nano* and *small* variants.
* **`yolov10n_det_coco80_640_640_INT8_cv181x.cvimodel`**: YOLOv10 Nano, highly efficient.
* **`yolox_s_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolox_m_...`**: YOLOX in *small* and *medium* variants.
* **`ppyoloe_det_coco80_640_640_INT8_cv181x.cvimodel`**: PP-YOLOE (developed by PaddlePaddle).

---

## 👤 Face Detection & Analysis
A set of models for detecting faces, estimating facial landmarks, and classifying facial attributes.

* **`scrfd_det_face_432_768_INT8_cv181x.cvimodel`** / **`scrfd_768_432_int8_1x.cvimodel`**: High-performance face detection (SCRFD).
* **`retinaface_mnet0.25_342_608.cvimodel`**: Lightweight face detection based on MobileNetV2.
* **`keypoint_face_v2_64_64_INT8_cv181x.cvimodel`**: Facial landmark detection (eyes, nose, mouth).
* **`feature_cviface_112_112_INT8_cv181x.cvimodel`**: Facial feature embedding extraction for **face recognition / identification**.
* **`cls_attribute_gender_age_glass_112_112_INT8_cv181x.cvimodel`**: Attribute classification for gender, age, and glasses.
* **`cls_attribute_gender_age_glass_emotion_...`**: Adds emotion recognition.
* **`cls_attribute_gender_age_glass_mask_...`**: Adds surgical mask detection.
* **`cls_rgbliveness_256_256_INT8_cv181x.cvimodel`**: RGB liveness detection (anti-spoofing) to prevent photo/screen fraud.

---

## 🚶 Person Detection, Pose Estimation & Segmentation
* **`mbv2_det_person_...`** / **`mobiledetv2-pedestrian-d0-ls-448.cvimodel`**: Dedicated pedestrian/person detection (MobileNetV2). Available in various resolutions (`256x384`, `512x896`, `896x896`).
* **`yolov8n_det_head_person_384_640_INT8_cv181x.cvimodel`**: Joint head and full-body person detection.
* **`yolov8n_det_head_shoulder_...`**: Head and shoulder detection (useful when lower body is obstructed).
* **`yolov8n_det_overlook_person_...`** / **`yolov8n_det_monitor_person_...`** : Person detection tuned for overhead views (top-down / ceiling security cameras).
* **`yolov8n_det_ir_person_...`**: Person detection optimized for **infrared (IR) / night vision** sensors.
* **`keypoint_yolov8pose_person17_384_640_INT8_cv181x.cvimodel`**: Human pose estimation (17 skeletal keypoints).
* **`keypoint_simcc_person17_256_192_INT8_cv181x.cvimodel`**: High-precision 17-keypoint pose estimation using SimCC.

---

## 🚘 License Plate Recognition & Transportation (ALPR / ADAS)
* **`yolov8n_det_license_plate_384_640_INT8_cv181x.cvimodel`**: License plate detection / localization.
* **`keypoint_license_plate_64_128_INT8_cv181x.cvimodel`**: 4-corner keypoint estimation for plate image rectification.
* **`recognition_license_plate_24_96_MIX_cv181x.cvimodel`**: License plate OCR character recognition.
* **`yolov8n_det_bicycle_motor_ebicycle_...`**: Detection of two-wheeled vehicles (bicycles, motorcycles, e-bikes).
* **`yolov8n_det_traffic_light_384_640_INT8_cv181x.cvimodel`**: Traffic light detection.
* **`lstr_det_lane_360_640_MIX_cv181x.cvimodel`**: Road lane detection / line markings (LSTR).

---

## ✋ Hand & Gesture Recognition
* **`yolov8n_det_hand_384_640_INT8_cv181x.cvimodel`**: Hand detection.
* **`keypoint_hand_128_128_INT8_cv181x.cvimodel`**: Hand keypoint tracking (21 finger joint skeleton).
* **`cls_hand_gesture_128_128_INT8_cv181x.cvimodel`**: Gesture classification (e.g., fist, open palm, OK sign).
* **`cls_keypoint_hand_gesture_1_42_INT8_cv181x.cvimodel`**: Joint-coordinate-based gesture classification.

---

## 🛡️ Security, Safety & Pet Monitoring
* **`yolov8n_det_fire_384_640_INT8_cv181x.cvimodel`** / **`yolov8n_det_fire_smoke_...`**: Fire and smoke detection.
* **`yolov8n_det_head_hardhat_576_960_INT8_cv181x.cvimodel`**: PPE inspection (safety hard hat detection).
* **`yolov8n_det_pet_person_...`** / **`yolov8n_det_face_head_person_pet_...`**: Smart home monitoring (pets and people).

---

## 🎨 Image Segmentation & Video Analytics
* **`topformer_seg_person_face_vehicle_384_640_INT8_cv181x.cvimodel`**: Semantic segmentation (pixel-level masking for faces, vehicles, and people).
* **`topformer_seg_motion_512_960_INT8_cv181x.cvimodel`**: Motion region segmentation in video streams.
* **`yolov8n_seg_coco80_640_640_INT8_cv181x.cvimodel`**: Dynamic instance segmentation with YOLOv8.
* **`tracking_feartrack_128_128_256_256_INT8_cv181x.cvimodel`**: Feature extraction for multi-object tracking (Re-Identification).
* **`aipq_sym_mars_BF16.cvimodel`**: AI Picture Quality (AIPQ) model for ISP post-processing image enhancement.

---

## 🔊 Audio Processing & Keyword Spotting (KWS)
* **`cls_sound_babay_cry_188_40_INT8_cv181x.cvimodel`**: Baby crying sound detection (smart baby monitor).
* **`cls_sound_nihaoshiyun_...`** / **`cls_sound_xiaoaixiaoai_...`** / **`cls_sound_dakaiqianlu_...`**: Embedded keyword voice activation (Chinese wake words such as *"Nihao Shiyun"*, *"Xiaoai Xiaoai"*).

---

## 🚀 Quick Usage Example
To test a face detection model directly from your Milk-V Duo S command line:

```bash
sample_vi_fd /usr/share/cvitek/models/tdl_models/scrfd_det_face_432_768_INT8_cv181x.cvimodel input.jpg output.jpg
