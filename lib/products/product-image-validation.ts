export const PRODUCT_IMAGE_MAX_BYTES = 5 * 1024 * 1024;
export const PRODUCT_IMAGE_MAX_DIMENSION = 2400;

const extensionByMimeType: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

type ProductImageFileInfo = {
  type: string;
  size: number;
  width: number;
  height: number;
};

export function getProductImageExtension(mimeType: string) {
  return extensionByMimeType[mimeType] ?? null;
}

export function validateProductImage(info: ProductImageFileInfo) {
  if (!getProductImageExtension(info.type)) {
    return "Usa una imagen JPEG, PNG o WebP.";
  }

  if (info.size <= 0 || info.size > PRODUCT_IMAGE_MAX_BYTES) {
    return "La imagen debe pesar como máximo 5 MB.";
  }

  if (
    info.width <= 0 ||
    info.height <= 0 ||
    info.width > PRODUCT_IMAGE_MAX_DIMENSION ||
    info.height > PRODUCT_IMAGE_MAX_DIMENSION
  ) {
    return "La imagen no puede superar 2400 × 2400 píxeles.";
  }

  return null;
}
