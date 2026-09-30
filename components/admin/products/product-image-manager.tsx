"use client";

import { ArrowDown, ArrowUp } from "lucide-react";
import Image from "next/image";
import { useState, type ChangeEvent } from "react";

import {
    getProductImageExtension,
    validateProductImage,
} from "@/lib/products/product-image-validation";
import { createClient } from "@/lib/supabase/client";

const productImageBucket = "product-images";

type ProductImage = {
  id: string;
  storagePath: string;
  publicUrl: string;
  altText: string | null;
  sortOrder: number;
  isPrimary: boolean;
};

type ProductImageManagerProps = {
  businessId: string;
  productId: string;
  productName: string;
  images: ProductImage[];
};

export function ProductImageManager({
  businessId,
  productId,
  productName,
  images: initialImages,
}: ProductImageManagerProps) {
  const [images, setImages] = useState(initialImages);
  const [altText, setAltText] = useState(productName);
  const [altTextDrafts, setAltTextDrafts] = useState<Record<string, string>>(
    Object.fromEntries(
      initialImages.map((image) => [image.id, image.altText ?? ""]),
    ),
  );
  const [isBusy, setIsBusy] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [statusMessage, setStatusMessage] = useState("");

  async function refreshImages() {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("product_images")
      .select("id, storage_path, public_url, alt_text, sort_order, is_primary")
      .eq("product_id", productId)
      .order("sort_order", { ascending: true })
      .order("created_at", { ascending: true });

    if (error) throw new Error("No se pudo actualizar la galería.");

    setImages(
      (data ?? []).map((image) => ({
        id: image.id,
        storagePath: image.storage_path,
        publicUrl: supabase.storage
          .from(productImageBucket)
          .getPublicUrl(image.storage_path).data.publicUrl,
        altText: image.alt_text,
        sortOrder: image.sort_order,
        isPrimary: image.is_primary,
      })),
    );
    setAltTextDrafts(
      Object.fromEntries(
        (data ?? []).map((image) => [image.id, image.alt_text ?? ""]),
      ),
    );
  }

  async function handleUpload(event: ChangeEvent<HTMLInputElement>) {
    const input = event.currentTarget;
    const files = Array.from(input.files ?? []);
    input.value = "";
    if (!files.length) return;

    setIsBusy(true);
    setErrorMessage("");
    setStatusMessage("");
    const supabase = createClient();

    try {
      for (const file of files) {
        const extension = getProductImageExtension(file.type);
        if (!extension) {
          throw new Error("Usa una imagen JPEG, PNG o WebP.");
        }

        const fileValidationError = validateProductImage({
          type: file.type,
          size: file.size,
          width: 1,
          height: 1,
        });
        if (fileValidationError) throw new Error(fileValidationError);

        let decodedImage: ImageBitmap;
        try {
          decodedImage = await createImageBitmap(file);
        } catch {
          throw new Error("No se pudo leer el archivo como una imagen válida.");
        }
        const validationError = validateProductImage({
          type: file.type,
          size: file.size,
          width: decodedImage.width,
          height: decodedImage.height,
        });
        decodedImage.close();
        if (validationError) throw new Error(validationError);

        const storagePath = `${businessId}/${productId}/${crypto.randomUUID()}.${extension}`;
        const { error: uploadError } = await supabase.storage
          .from(productImageBucket)
          .upload(storagePath, file, {
            cacheControl: "31536000",
            contentType: file.type,
            upsert: false,
          });

        if (uploadError) {
          throw new Error(
            "No se pudo cargar la imagen. Revisa el formato y el tamaño.",
          );
        }

        const { error: registerError } = await supabase.rpc(
          "register_product_image",
          {
            p_product_id: productId,
            p_storage_path: storagePath,
            p_alt_text: altText.trim() || productName,
          },
        );

        if (registerError) {
          await supabase.storage.from(productImageBucket).remove([storagePath]);
          throw new Error(
            "La imagen se cargó, pero no se pudo asociar al producto.",
          );
        }
      }

      await refreshImages();
      setStatusMessage(
        files.length === 1 ? "Imagen agregada." : "Imágenes agregadas.",
      );
    } catch (error) {
      const uploadErrorMessage =
        error instanceof Error
          ? error.message
          : "No se pudieron cargar las imágenes.";
      try {
        await refreshImages();
        setErrorMessage(uploadErrorMessage);
      } catch {
        setErrorMessage(
          `${uploadErrorMessage} Recarga la página para actualizar la galería.`,
        );
      }
    } finally {
      setIsBusy(false);
    }
  }

  async function setPrimary(imageId: string) {
    setIsBusy(true);
    setErrorMessage("");
    setStatusMessage("");

    try {
      const supabase = createClient();
      const { error } = await supabase.rpc("set_product_image_primary", {
        p_product_id: productId,
        p_image_id: imageId,
      });
      if (error) throw new Error("No se pudo cambiar la imagen principal.");
      await refreshImages();
      setStatusMessage("Imagen principal actualizada.");
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "No se pudo cambiar la imagen principal.",
      );
    } finally {
      setIsBusy(false);
    }
  }

  async function moveImage(imageId: string, direction: -1 | 1) {
    setIsBusy(true);
    setErrorMessage("");
    setStatusMessage("");

    try {
      const supabase = createClient();
      const { error } = await supabase.rpc("move_product_image", {
        p_product_id: productId,
        p_image_id: imageId,
        p_direction: direction,
      });
      if (error)
        throw new Error("No se pudo cambiar el orden de las imágenes.");
      await refreshImages();
      setStatusMessage("Orden de imágenes actualizado.");
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "No se pudo cambiar el orden de las imágenes.",
      );
    } finally {
      setIsBusy(false);
    }
  }

  async function saveAltText(imageId: string) {
    const nextAltText = (altTextDrafts[imageId] ?? "").trim();
    if (!nextAltText || nextAltText.length > 300) {
      setErrorMessage(
        "El texto alternativo es obligatorio y admite hasta 300 caracteres.",
      );
      return;
    }

    setIsBusy(true);
    setErrorMessage("");
    setStatusMessage("");

    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("product_images")
        .update({ alt_text: nextAltText })
        .eq("id", imageId)
        .eq("product_id", productId);
      if (error) throw new Error("No se pudo guardar el texto alternativo.");
      await refreshImages();
      setStatusMessage("Texto alternativo guardado.");
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "No se pudo guardar el texto alternativo.",
      );
    } finally {
      setIsBusy(false);
    }
  }

  async function deleteImage(image: ProductImage) {
    if (!window.confirm(`¿Eliminar la imagen de ${productName}?`)) return;

    setIsBusy(true);
    setErrorMessage("");
    setStatusMessage("");

    try {
      const supabase = createClient();
      const replacement =
        images.find(
          (candidate) => candidate.id !== image.id && candidate.isPrimary,
        ) ?? images.find((candidate) => candidate.id !== image.id);

      if (replacement) {
        const { error: primaryError } = await supabase.rpc(
          "set_product_image_primary",
          {
            p_product_id: productId,
            p_image_id: replacement.id,
          },
        );
        if (primaryError) {
          throw new Error(
            "No se pudo cambiar la imagen principal antes de eliminarla.",
          );
        }
      }

      const { error: metadataError } = await supabase
        .from("product_images")
        .delete()
        .eq("id", image.id)
        .eq("product_id", productId);
      if (metadataError)
        throw new Error("No se pudo eliminar el registro de la imagen.");

      const { error: storageError } = await supabase.storage
        .from(productImageBucket)
        .remove([image.storagePath]);
      await refreshImages();

      if (storageError) {
        setErrorMessage(
          "La imagen se quitó del catálogo, pero el archivo no pudo eliminarse de Storage.",
        );
      } else {
        setStatusMessage("Imagen eliminada.");
      }
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "No se pudo eliminar la imagen.",
      );
    } finally {
      setIsBusy(false);
    }
  }

  return (
    <section aria-labelledby="product-images-title" className="space-y-4">
      <div className="flex flex-col gap-4 border-b border-[var(--color-border)] pb-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 className="text-lg font-semibold" id="product-images-title">
            Imágenes del producto
          </h2>
          <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
            JPEG, PNG o WebP · hasta 5 MB · máximo 2400 × 2400 px
          </p>
        </div>
        <div className="grid gap-3 sm:min-w-80 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
          <label className="space-y-1.5 text-sm font-medium">
            <span>Texto alternativo para la carga</span>
            <input
              className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 text-sm outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
              maxLength={300}
              onChange={(event) => setAltText(event.currentTarget.value)}
              required
              value={altText}
            />
          </label>
          <label className="inline-flex min-h-10 cursor-pointer items-center justify-center rounded-md bg-[var(--color-ink)] px-4 text-sm font-medium text-white transition hover:opacity-95 has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-60">
            {isBusy ? "Procesando…" : "Agregar imágenes"}
            <input
              accept="image/jpeg,image/png,image/webp"
              className="sr-only"
              disabled={isBusy || !altText.trim()}
              multiple
              onChange={handleUpload}
              type="file"
            />
          </label>
        </div>
      </div>

      {errorMessage && (
        <p className="text-sm text-rose-700" role="alert">
          {errorMessage}
        </p>
      )}
      {statusMessage && (
        <p className="text-sm text-emerald-700" role="status">
          {statusMessage}
        </p>
      )}

      {images.length === 0 ? (
        <p className="border-y border-[var(--color-border)] py-8 text-center text-sm text-[var(--color-ink-muted)]">
          Este producto aún no tiene imágenes.
        </p>
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {images.map((image, index) => (
            <li
              className="overflow-hidden rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)]"
              key={image.id}
            >
              <div className="relative aspect-[4/3] bg-[var(--color-surface-muted)]">
                <Image
                  alt={image.altText ?? productName}
                  className="object-cover"
                  fill
                  sizes="(max-width: 640px) 100vw, (max-width: 1280px) 50vw, 33vw"
                  src={image.publicUrl}
                />
                {image.isPrimary && (
                  <span className="absolute top-3 left-3 rounded-sm bg-white px-2 py-1 text-xs font-semibold text-[var(--color-ink)]">
                    Principal
                  </span>
                )}
              </div>
              <div className="space-y-3 p-3">
                <label className="block space-y-1.5 text-sm font-medium">
                  <span>Texto alternativo</span>
                  <input
                    className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 text-sm outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                    maxLength={300}
                    onChange={(event) =>
                      setAltTextDrafts((current) => ({
                        ...current,
                        [image.id]: event.currentTarget.value,
                      }))
                    }
                    value={altTextDrafts[image.id] ?? ""}
                  />
                </label>
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex gap-1">
                    <button
                      aria-label={`Mover ${image.altText ?? productName} hacia arriba`}
                      className="size-9 rounded-md border border-[var(--color-border)] text-sm disabled:opacity-40"
                      disabled={isBusy || index === 0}
                      onClick={() => moveImage(image.id, -1)}
                      title="Mover hacia arriba"
                      type="button"
                    >
                      <ArrowUp aria-hidden="true" size={16} />
                    </button>
                    <button
                      aria-label={`Mover ${image.altText ?? productName} hacia abajo`}
                      className="size-9 rounded-md border border-[var(--color-border)] text-sm disabled:opacity-40"
                      disabled={isBusy || index === images.length - 1}
                      onClick={() => moveImage(image.id, 1)}
                      title="Mover hacia abajo"
                      type="button"
                    >
                      <ArrowDown aria-hidden="true" size={16} />
                    </button>
                  </div>
                  <div className="flex flex-wrap justify-end gap-2">
                    {!image.isPrimary && (
                      <button
                        className="min-h-9 rounded-md border border-[var(--color-border)] px-3 text-xs font-medium hover:bg-[var(--color-surface-muted)] disabled:opacity-50"
                        disabled={isBusy}
                        onClick={() => setPrimary(image.id)}
                        type="button"
                      >
                        Hacer principal
                      </button>
                    )}
                    <button
                      className="min-h-9 rounded-md px-3 text-xs font-medium text-rose-700 hover:bg-rose-50 disabled:opacity-50"
                      disabled={isBusy}
                      onClick={() => deleteImage(image)}
                      type="button"
                    >
                      Eliminar
                    </button>
                    <button
                      className="min-h-9 rounded-md bg-[var(--color-ink)] px-3 text-xs font-medium text-white hover:opacity-95 disabled:opacity-50"
                      disabled={isBusy}
                      onClick={() => saveAltText(image.id)}
                      type="button"
                    >
                      Guardar texto
                    </button>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
