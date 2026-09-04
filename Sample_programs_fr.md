# Guide des Programmes d'Exemple Cvitek / CVI-TDL sur Milk-V Duo S

Ce document présente la fonction, la catégorisation et l'utilisation des exemples exécutables situés dans le répertoire `/usr/share/cvitek/samples/` sur la carte **Milk-V Duo S** (SOPHGO SG2000).

Ces utilitaires exploitent le **NPU / TPU** (accélérateur IA) ainsi que le moteur de traitement d'image matériel **IVE / VPSS** du SoC.

---

## 🛠️ 1. Outillage & Benchmarks TPU

Ces programmes permettent de tester, manipuler et évaluer les performances des modèles IA sur le matériel.

| Programme | Description / Fonction |
| :--- | :--- |
| `cvimodel_tool` | Inspecte la structure, les couches et les métadonnées d'un fichier `.cvimodel`. |
| `model_runner` | Charge un fichier `.cvimodel` et exécute une inférence simple sur une entrée de test. |
| `multi_model_tester` | Teste l'exécution simultanée ou séquentielle de plusieurs modèles IA. |
| `multi_thread_tester` | Évalue les performances et la stabilité de l'inférence en multi-threading. |
| `stress_tester` | Effectue des tests de charge prolongés sur le TPU. |
| `mat2npz` / `npz2mat` / `npy2mat` | Outils de conversion entre les formats de matrices NumPy (`.npy`/`.npz`) et fichiers binaires C (`.mat`). |

---

## 🖼️ 2. Inférence IA sur Image Fixe (`sample_img_*` / `sample_yolo*`)

Ces binaires prennent en entrée un fichier `.cvimodel` et une image (JPEG/PNG), exécutent l'inférence IA, et génèrent une image de sortie annotée.

### Analyse Faciale & Humaine
* **`sample_img_face_det`** : Détection de visages.
* **`sample_img_face_recognition`** : Reconnaissance et identification faciale.
* **`sample_img_face_landmarker`** : Extraction des points caractéristiques du visage (*landmarks*).
* **`sample_img_face_attribute_cls`** : Classification des attributs faciaux (âge, genre, expression).
* **`sample_img_face_liveness`** : Détection de vivacité faciale (anti-usurpation / anti-spoofing).
* **`sample_img_face_mask`** : Détection du port du masque chirurgical.
* **`sample_img_face_quality`** : Évaluation de la qualité d'image du visage.
* **`sample_img_pose`** : Estimation de la pose corporelle (squelette 2D).
* **`sample_img_fatigue_eye` / `sample_img_fatigue_yawn`** : Détection de fatigue (clignement des yeux, bâillements).

### Détection d'Objets & Segmentation (YOLO & Autres)
* **`sample_yolov5` / `sample_yolov6` / `sample_yolov7` / `sample_yolov8` / `sample_yolov10` / `sample_yolov11` / `sample_yolox`** : Détection d'objets générale sur les différentes générations de YOLO.
* **`sample_yolov8_roi` / `sample_img_detection_roi`** : Détection d'objets restreinte à une zone d'intérêt (ROI).
* **`sample_yolo_world_v2`** : Détection d'objets à vocabulaire ouvert (*Open-Vocabulary Object Detection*).
* **`sample_ppyoloe`** : Modèle de détection d'objets PP-YOLOE.
* **`sample_img_yolov8_seg`** : Segmentation d'instance avec YOLOv8.
* **`sample_img_topformer_seg`** : Segmentation sémanitque en temps réel basée sur TopFormer.

### Mains, Plaques & Analyse Routière (ADAS)
* **`sample_img_hand_det`** : Détection de mains.
* **`sample_img_hand_keypoint`** : Détection des points clés / articulation des doigts.
* **`sample_img_hand_cls`** : Classification des gestes de la main.
* **`sample_img_lpd_lpr`** : Détection et reconnaissance de plaques d'immatriculation (ALPR).
* **`sample_img_lpd_lpr_keypoint`** : Détection des coins / points clés des plaques.
* **`sample_img_lane_det`** : Détection des lignes de voie de circulation (ADAS).

### Modèles Multimodaux & Audio
* **`sample_blip_cap` / `sample_blip_itm` / `sample_blip_vqa`** : Légendage d'images, correspondance image-texte et réponse aux questions visuelles (BLIP).
* **`sample_audio_cls` / `sample_aud_cls_read` / `sample_aud_order`** : Classification audio et reconnaissance de mots-clés vocaux.

---

## 📹 3. Traitement du Flux Caméra en Temps Réel (`sample_vi_*` & `sample_stream_*`)

Ces démos se connectent directement à l'entrée vidéo (**VI** - Video Input) pour effectuer du traitement en temps réel à partir d'un flux de caméra (MIPI / USB).

| Programme | Description |
| :--- | :--- |
| `sample_vi_od` | Détection d'objets en direct sur flux vidéo. |
| `sample_vi_fd` | Détection de visages sur flux vidéo. |
| `sample_vi_face_recog` | Reconnaissance faciale en temps réel. |
| `sample_vi_pose` | Estimation de pose corporelle en temps réel. |
| `sample_vi_occ` | Détection d'occlusion sur flux vidéo. |
| `sample_stream_hardhat` | Surveillance et détection du port de casque de chantier. |
| `sample_stream_personvehicle_cross` | Franchissement de ligne virtuelle (piétons et véhicules). |
| `sample_stream_consumer_counting` | Comptage de personnes en temps réel. |

---

## ⚡ 4. Traitement d'Image Matériel IVE (`test_*` & `sample_*`)

Programmes de bas niveau testant l'accélérateur d'image matériel (**IVE / VPSS**) sans passer par le réseau de neurones TPU.

* **Filtres & Transformations** : `test_resize_c`, `test_sobel_grad_c`, `test_histEq_c`, `test_filter_c`, `test_csc_c` (conversion colorimétrique).
* **Arithmétique & Logique** : `sample_add`, `sample_sub`, `sample_and`, `sample_or`, `sample_xor`, `sample_alpha_blend`.
* **Morphologie & Extraction** : `sample_dilate`, `sample_morph`, `sample_hog`, `sample_lbp`, `sample_integral_image`.

---

## 🚀 Exemple d'Utilisation

### 1. Afficher l'aide d'une commande
Exécutez n'importe quel binaire sans paramètre pour afficher la syntaxe attendue :
```bash
/usr/share/cvitek/samples/sample_img_face_det
