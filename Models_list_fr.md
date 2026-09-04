# Catalogue des modèles pré-entraînés (.cvimodel) - Milk-V Duo S (CV181X)

Cette liste répertorie l'utilité des modèles IA pré-installés dans `/usr/share/cvitek/models/` sur la carte Milk-V Duo S. Ces modèles sont optimisés pour le NPU/TPU intégré (formats `INT8`, `MIX` et `BF16`) via la bibliothèque **CVI-TDL** / **Cvitek SDK**.

---

## 🎯 Détection d'Objets Générale (COCO 80 classes)
Modèles entraînés sur le dataset COCO pour la détection multi-objets courante (personnes, véhicules, animaux, objets du quotidien).

* **`yolov5s_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov5m_...`** : YOLOv5 en déclinaisons *small* (rapide) et *medium* (plus précis).
* **`yolov6n_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov6s_...`** : YOLOv6 en versions *nano* et *small*.
* **`yolov7_tiny_det_coco80_640_640_INT8_cv181x.cvimodel`** : YOLOv7 ultra-léger optimisé pour l'embarqué.
* **`yolov8n_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolov8s_...`** : YOLOv8 en versions *nano* et *small*.
* **`yolov10n_det_coco80_640_640_INT8_cv181x.cvimodel`** : YOLOv10 Nano, hautement efficient.
* **`yolox_s_det_coco80_640_640_INT8_cv181x.cvimodel`** / **`yolox_m_...`** : YOLOX en versions *small* et *medium*.
* **`ppyoloe_det_coco80_640_640_INT8_cv181x.cvimodel`** : PP-YOLOE (développé par PaddlePaddle).

---

## 👤 Détection & Analyse de Visages
Ensemble de modèles pour la détection, le repérage de points caractéristiques et l'analyse d'attributs faciaux.

* **`scrfd_det_face_432_768_INT8_cv181x.cvimodel`** / **`scrfd_768_432_int8_1x.cvimodel`** : Détection de visages haute performance (SCRFD).
* **`retinaface_mnet0.25_342_608.cvimodel`** : Détection de visages légère basée sur MobileNetV2.
* **`keypoint_face_v2_64_64_INT8_cv181x.cvimodel`** : Repérage des points clés du visage (yeux, nez, bouche).
* **`feature_cviface_112_112_INT8_cv181x.cvimodel`** : Extraction de vecteur/empreinte faciale pour la **reconnaissance d'identité**.
* **`cls_attribute_gender_age_glass_112_112_INT8_cv181x.cvimodel`** : Classification du genre, de l'âge et du port de lunettes.
* **`cls_attribute_gender_age_glass_emotion_...`** : Ajoute la reconnaissance d'émotions.
* **`cls_attribute_gender_age_glass_mask_...`** : Ajoute la détection de masque chirurgical.
* **`cls_rgbliveness_256_256_INT8_cv181x.cvimodel`** : Détection de vivacité (anti-spoofing) pour bloquer les fraudes par photo.

---

## 🚶 Détection, Pose & Segmentation Humaine
* **`mbv2_det_person_...`** / **`mobiledetv2-pedestrian-d0-ls-448.cvimodel`** : Détection ciblée de piétons/personnes (MobileNetV2). Résolutions variées (`256x384`, `512x896`, `896x896`).
* **`yolov8n_det_head_person_384_640_INT8_cv181x.cvimodel`** : Détection conjointe de têtes et de corps complets.
* **`yolov8n_det_head_shoulder_...`** : Détection de la tête et des épaules (utile si le corps est masqué).
* **`yolov8n_det_overlook_person_...`** / **`yolov8n_det_monitor_person_...`** : Détection adaptée aux vues de dessus (caméras de plafond/surveillance).
* **`yolov8n_det_ir_person_...`** : Détection de personnes optimisée pour les caméras **infrarouges / vision nocturne**.
* **`keypoint_yolov8pose_person17_384_640_INT8_cv181x.cvimodel`** : Estimation de pose (17 points d'articulations / squelette humain).
* **`keypoint_simcc_person17_256_192_INT8_cv181x.cvimodel`** : Estimation de pose ultra-précise via SimCC.

---

## 🚘 Plaques d'Immatriculation & Transports (ALPR / ADAS)
* **`yolov8n_det_license_plate_384_640_INT8_cv181x.cvimodel`** : Localisation des plaques d'immatriculation.
* **`keypoint_license_plate_64_128_INT8_cv181x.cvimodel`** : Repérage des 4 coins de la plaque pour le redressement de l'image.
* **`recognition_license_plate_24_96_MIX_cv181x.cvimodel`** : OCR / Lecture des caractères de la plaque.
* **`yolov8n_det_bicycle_motor_ebicycle_...`** : Détection spécifique des deux-roues (vélos, motos, trottinettes).
* **`yolov8n_det_traffic_light_384_640_INT8_cv181x.cvimodel`** : Détection des feux de circulation.
* **`lstr_det_lane_360_640_MIX_cv181x.cvimodel`** : Détection du marquage au sol / voies de circulation (LSTR).

---

## ✋ Mains & Reconnaissance de Gestes
* **`yolov8n_det_hand_384_640_INT8_cv181x.cvimodel`** : Détection de mains.
* **`keypoint_hand_128_128_INT8_cv181x.cvimodel`** : Suivi des points clés de la main (squelette des 21 articulations).
* **`cls_hand_gesture_128_128_INT8_cv181x.cvimodel`** : Classification de gestes de la main (ex: poing, paume, signe OK).
* **`cls_keypoint_hand_gesture_1_42_INT8_cv181x.cvimodel`** : Classification de gestes basée directement sur les coordonnées des articulations.

---

## 🛡️ Sécurité, Domotique & Animaux
* **`yolov8n_det_fire_384_640_INT8_cv181x.cvimodel`** / **`yolov8n_det_fire_smoke_...`** : Détection de départ de feu et de fumée.
* **`yolov8n_det_head_hardhat_576_960_INT8_cv181x.cvimodel`** : Vérification des EPI (port du casque de chantier).
* **`yolov8n_det_pet_person_...`** / **`yolov8n_det_face_head_person_pet_...`** : Surveillance domestique mixte (animaux de compagnie et humains).

---

## 🎨 Segmentation & Suivi Vidéo
* **`topformer_seg_person_face_vehicle_384_640_INT8_cv181x.cvimodel`** : Segmentation sémantique (détourage au pixel des visages, véhicules et personnes).
* **`topformer_seg_motion_512_960_INT8_cv181x.cvimodel`** : Segmentation des régions d'intérêt en mouvement.
* **`yolov8n_seg_coco80_640_640_INT8_cv181x.cvimodel`** : Segmentation d'instances dynamique YOLOv8.
* **`tracking_feartrack_128_128_256_256_INT8_cv181x.cvimodel`** : Extraction de features pour le suivi multi-objets (Re-Identification).
* **`aipq_sym_mars_BF16.cvimodel`** : Traitement ISP par IA pour l'amélioration de la qualité de l'image (AI Picture Quality).

---

## 🔊 Traitement Audio & Mots-Clés (KWS - Keyword Spotting)
* **`cls_sound_babay_cry_188_40_INT8_cv181x.cvimodel`** : Détection audio du pleur de bébé (écoute-bébé).
* **`cls_sound_nihaoshiyun_...`** / **`cls_sound_xiaoaixiaoai_...`** / **`cls_sound_dakaiqianlu_...`** : Reconnaissance vocale embarquée / réveil par mots-clés en chinois (*« Nihao Shiyun »*, *« Xiaoai Xiaoai »*, etc.).

---

## 🚀 Utilisation rapide
Pour tester un modèle de détection de visage directement depuis le terminal de votre Milk-V Duo S :

```bash
sample_vi_fd /usr/share/cvitek/models/tdl_models/scrfd_det_face_432_768_INT8_cv181x.cvimodel input.jpg output.jpg
