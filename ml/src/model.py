"""FloraScan Neural Classifier Model Module.

Wraps timm EfficientNet-Lite0 / MobileNetV3 backbones with custom classification head,
differential learning rate parameter grouping, and probability inference methods.
"""

from typing import Any

import timm
import torch
import torch.nn as nn


class FloraScanModel(nn.Module):
    """Deep Neural Network classifier for Solanaceae crop leaf diseases."""

    def __init__(
        self,
        backbone_name: str = "efficientnet_lite0",
        num_classes: int = 20,
        pretrained: bool = True,
        dropout_rate: float = 0.25,
    ) -> None:
        super().__init__()
        self.backbone_name = backbone_name
        self.num_classes = num_classes

        # Instantiate backbone via timm
        self.backbone = timm.create_model(
            backbone_name,
            pretrained=pretrained,
            num_classes=num_classes,
            drop_rate=dropout_rate,
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Execute forward pass and return raw logits (shape: [batch_size, num_classes])."""
        return self.backbone(x)

    @torch.no_grad()
    def predict_probabilities(self, x: torch.Tensor) -> torch.Tensor:
        """Compute Softmax probabilities for leaf diagnosis."""
        logits = self.forward(x)
        return torch.softmax(logits, dim=-1)

    def get_parameter_groups(
        self,
        lr_head: float = 1e-3,
        lr_backbone: float = 1e-4,
        weight_decay: float = 1e-2,
    ) -> list[dict[str, Any]]:
        """Split parameters into backbone and classification head for differential learning rates."""
        classifier = self.backbone.get_classifier()
        classifier_params = set(classifier.parameters())

        head_params = []
        backbone_params = []

        for param in self.backbone.parameters():
            if not param.requires_grad:
                continue
            if param in classifier_params:
                head_params.append(param)
            else:
                backbone_params.append(param)

        return [
            {
                "params": head_params,
                "lr": lr_head,
                "weight_decay": weight_decay,
            },
            {
                "params": backbone_params,
                "lr": lr_backbone,
                "weight_decay": weight_decay,
            },
        ]


def build_model(config: dict[str, Any]) -> FloraScanModel:
    """Factory creating FloraScanModel from configuration dictionary."""
    model_cfg = config.get("model", {})
    return FloraScanModel(
        backbone_name=model_cfg.get("backbone", "efficientnet_lite0"),
        num_classes=model_cfg.get("num_classes", 20),
        pretrained=model_cfg.get("pretrained", True),
        dropout_rate=model_cfg.get("dropout_rate", 0.25),
    )
