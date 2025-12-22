import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader, WeightedRandomSampler
from PIL import Image, UnidentifiedImageError
import numpy as np
import os
import cv2

# =================== CONFIGURATION ===================
DATA_DIR = r"C:\Users\hajee\Documents\A_final_demo\Aura_v1\dataset\skin_tone_dataset"
BATCH_SIZE = 32
EPOCHS = 12
NUM_CLASSES = 3
MODEL_PATH = "models/skin_tone_cnn.pth"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

CLASS_NAMES = ['fair', 'medium', 'dark']

# =================== SAFE IMAGE LOADER ===================
def safe_loader(path):
    """Safely loads image, skipping unreadable ones."""
    try:
        with Image.open(path) as img:
            return img.convert("RGB")
    except UnidentifiedImageError:
        print(f"⚠️ Skipping unreadable image: {path}")
        return Image.new("RGB", (224, 224), (0, 0, 0))

# =================== PREPROCESSING ===================
class EqualizeLAB:
    """Normalize lighting while keeping true skin tone."""
    def __call__(self, img):
        img = np.array(img)
        img = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
        l, a, b = cv2.split(img)
        l = cv2.equalizeHist(l)
        img = cv2.merge((l, a, b))
        img = cv2.cvtColor(img, cv2.COLOR_LAB2RGB)
        return Image.fromarray(img)

transform = transforms.Compose([
    EqualizeLAB(),
    transforms.Resize((224, 224)),
    transforms.RandomHorizontalFlip(),
    transforms.ColorJitter(brightness=0.08, contrast=0.08, saturation=0.05),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])

# =================== HSV FEATURE FUNCTION ===================
def compute_hsv_vector(img):
    """Compute mean HSV values (scaled 0–1) for the image."""
    np_img = np.array(img)
    hsv = cv2.cvtColor(np_img, cv2.COLOR_RGB2HSV)
    h_mean = hsv[:, :, 0].mean() / 179.0
    s_mean = hsv[:, :, 1].mean() / 255.0
    v_mean = hsv[:, :, 2].mean() / 255.0
    return np.array([h_mean, s_mean, v_mean], dtype=np.float32)

# =================== CUSTOM DATASET ===================
class ToneDataset(torch.utils.data.Dataset):
    def __init__(self, folder_path, transform, class_to_idx):
        self.data = []
        self.transform = transform
        self.class_to_idx = class_to_idx

        for tone in class_to_idx.keys():
            tone_dir = os.path.join(folder_path, tone)
            for img_name in os.listdir(tone_dir):
                img_path = os.path.join(tone_dir, img_name)
                if img_name.lower().endswith(('.png', '.jpg', '.jpeg')):
                    self.data.append((img_path, class_to_idx[tone]))

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        img_path, label = self.data[idx]
        img = safe_loader(img_path)
        hsv_vec = compute_hsv_vector(img)
        img_tensor = self.transform(img)
        return img_tensor, torch.tensor(hsv_vec), label

# =================== LOAD DATA ===================
train_dataset = ToneDataset(
    os.path.join(DATA_DIR, "train"), transform, {cls: i for i, cls in enumerate(CLASS_NAMES)}
)
val_dataset = ToneDataset(
    os.path.join(DATA_DIR, "val"), transform, {cls: i for i, cls in enumerate(CLASS_NAMES)}
)

# Weighted sampler for class balance
targets = [label for _, _, label in train_dataset]
class_counts = np.bincount(targets)
weights = 1.0 / class_counts
sample_weights = [weights[t] for t in targets]
sampler = WeightedRandomSampler(sample_weights, len(sample_weights))

train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, sampler=sampler, num_workers=0)
val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)

# =================== MODEL (ResNet + HSV) ===================
class ResNetHSV(nn.Module):
    def __init__(self, num_classes=3):
        super().__init__()
        self.base = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)
        num_features = self.base.fc.in_features
        self.base.fc = nn.Identity()  # remove default FC layer
        self.classifier = nn.Sequential(
            nn.Linear(num_features + 3, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes)
        )

    def forward(self, x, hsv):
        f = self.base(x)
        combined = torch.cat((f, hsv), dim=1)
        out = self.classifier(combined)
        return out

model = ResNetHSV(NUM_CLASSES).to(DEVICE)

# =================== LOSS & OPTIMIZER ===================
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=2e-4)

# =================== TRAINING LOOP ===================
for epoch in range(EPOCHS):
    model.train()
    running_loss = 0.0

    for imgs, hsv_vecs, labels in train_loader:
        imgs, hsv_vecs, labels = imgs.to(DEVICE), hsv_vecs.to(DEVICE), labels.to(DEVICE)

        optimizer.zero_grad()
        outputs = model(imgs, hsv_vecs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item()

    avg_loss = running_loss / len(train_loader)
    print(f"Epoch {epoch+1}/{EPOCHS} - Training Loss: {avg_loss:.4f}")

    # =================== VALIDATION ===================
    model.eval()
    correct = 0
    total = 0

    with torch.no_grad():
        for imgs, hsv_vecs, labels in val_loader:
            imgs, hsv_vecs, labels = imgs.to(DEVICE), hsv_vecs.to(DEVICE), labels.to(DEVICE)
            outputs = model(imgs, hsv_vecs)
            _, predicted = torch.max(outputs, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    acc = 100 * correct / total
    print(f"✅ Validation Accuracy: {acc:.2f}%")

# =================== SAVE MODEL ===================
os.makedirs("models", exist_ok=True)
torch.save(model.state_dict(), MODEL_PATH)
print(f"\n🎯 Hybrid model saved to {MODEL_PATH}")
