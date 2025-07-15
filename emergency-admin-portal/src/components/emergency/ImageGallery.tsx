import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  X,
  Download,
  Share,
  ZoomIn,
  ZoomOut,
  RotateCw,
  ChevronLeft,
  ChevronRight,
  Camera,
  MapPin,
  Clock,
  User,
  FileImage,
  Maximize2
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface EmergencyImage {
  id: string;
  url: string;
  thumbnail: string;
  filename: string;
  size: number;
  uploadedAt: Date;
  uploadedBy: {
    id: string;
    name: string;
    role: string;
  };
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  metadata?: {
    width: number;
    height: number;
    type: string;
  };
}

interface ImageGalleryProps {
  images: EmergencyImage[];
  emergencyId: string;
  onImageUpload?: (files: File[]) => void;
}

export const ImageGallery: React.FC<ImageGalleryProps> = ({
  images,
  emergencyId,
  onImageUpload,
}) => {
  const [selectedImageIndex, setSelectedImageIndex] = useState<number | null>(null);
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);

  const selectedImage = selectedImageIndex !== null ? images[selectedImageIndex] : null;

  const openLightbox = (index: number) => {
    setSelectedImageIndex(index);
    setZoom(1);
    setRotation(0);
  };

  const closeLightbox = () => {
    setSelectedImageIndex(null);
    setZoom(1);
    setRotation(0);
  };

  const nextImage = () => {
    if (selectedImageIndex !== null && selectedImageIndex < images.length - 1) {
      setSelectedImageIndex(selectedImageIndex + 1);
      setZoom(1);
      setRotation(0);
    }
  };

  const prevImage = () => {
    if (selectedImageIndex !== null && selectedImageIndex > 0) {
      setSelectedImageIndex(selectedImageIndex - 1);
      setZoom(1);
      setRotation(0);
    }
  };

  const handleZoomIn = () => setZoom(prev => Math.min(prev + 0.25, 3));
  const handleZoomOut = () => setZoom(prev => Math.max(prev - 0.25, 0.5));
  const handleRotate = () => setRotation(prev => (prev + 90) % 360);

  const handleDownload = (image: EmergencyImage) => {
    const link = document.createElement('a');
    link.href = image.url;
    link.download = image.filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length > 0) {
      onImageUpload?.(files);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <>
      <Card className="border-0 shadow-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Camera className="h-5 w-5 text-blue-500" />
              <CardTitle>Emergency Images ({images.length})</CardTitle>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="file"
                multiple
                accept="image/*"
                onChange={handleFileUpload}
                className="hidden"
                id="image-upload"
              />
              <label htmlFor="image-upload">
                <Button variant="outline" size="sm" className="cursor-pointer" asChild>
                  <span>
                    <Camera className="h-4 w-4 mr-2" />
                    Add Images
                  </span>
                </Button>
              </label>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {images.length === 0 ? (
            <div className="text-center py-12">
              <FileImage className="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-gray-900 mb-2">No images uploaded</h3>
              <p className="text-gray-500 mb-6">Images from the emergency report will appear here</p>
              <label htmlFor="image-upload">
                <Button className="cursor-pointer" asChild>
                  <span>
                    <Camera className="h-4 w-4 mr-2" />
                    Upload First Image
                  </span>
                </Button>
              </label>
            </div>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {images.map((image, index) => (
                <div
                  key={image.id}
                  className="group relative aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:shadow-lg transition-all duration-300"
                  onClick={() => openLightbox(index)}
                >
                  <img
                    src={image.thumbnail}
                    alt={image.filename}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  
                  {/* Overlay */}
                  <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all duration-300 flex items-center justify-center">
                    <Maximize2 className="h-6 w-6 text-white opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  </div>
                  
                  {/* Image info */}
                  <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-3">
                    <div className="text-white text-xs">
                      <div className="flex items-center gap-1 mb-1">
                        <User className="h-3 w-3" />
                        <span>{image.uploadedBy.name}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        <span>{formatDistanceToNow(image.uploadedAt, { addSuffix: true })}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Lightbox Modal */}
      {selectedImage && (
        <div className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center">
          <div className="relative w-full h-full flex items-center justify-center p-4">
            {/* Close button */}
            <Button
              variant="ghost"
              size="sm"
              onClick={closeLightbox}
              className="absolute top-4 right-4 text-white hover:bg-white hover:bg-opacity-20 cursor-pointer z-10"
            >
              <X className="h-6 w-6" />
            </Button>

            {/* Navigation buttons */}
            {images.length > 1 && (
              <>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={prevImage}
                  disabled={selectedImageIndex === 0}
                  className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white hover:bg-white hover:bg-opacity-20 cursor-pointer disabled:cursor-not-allowed"
                >
                  <ChevronLeft className="h-8 w-8" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={nextImage}
                  disabled={selectedImageIndex === images.length - 1}
                  className="absolute right-4 top-1/2 transform -translate-y-1/2 text-white hover:bg-white hover:bg-opacity-20 cursor-pointer disabled:cursor-not-allowed"
                >
                  <ChevronRight className="h-8 w-8" />
                </Button>
              </>
            )}

            {/* Image controls */}
            <div className="absolute top-4 left-4 flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={handleZoomOut}
                className="text-white hover:bg-white hover:bg-opacity-20 cursor-pointer"
              >
                <ZoomOut className="h-4 w-4" />
              </Button>
              <span className="text-white text-sm">{Math.round(zoom * 100)}%</span>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleZoomIn}
                className="text-white hover:bg-white hover:bg-opacity-20 cursor-pointer"
              >
                <ZoomIn className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleRotate}
                className="text-white hover:bg-white hover:bg-opacity-20 cursor-pointer"
              >
                <RotateCw className="h-4 w-4" />
              </Button>
            </div>

            {/* Image actions */}
            <div className="absolute bottom-4 right-4 flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleDownload(selectedImage)}
                className="text-white hover:bg-white hover:bg-opacity-20 cursor-pointer"
              >
                <Download className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className="text-white hover:bg-white hover:bg-opacity-20 cursor-pointer"
              >
                <Share className="h-4 w-4" />
              </Button>
            </div>

            {/* Main image */}
            <div className="max-w-full max-h-full overflow-hidden">
              <img
                src={selectedImage.url}
                alt={selectedImage.filename}
                className="max-w-full max-h-full object-contain transition-transform duration-300"
                style={{
                  transform: `scale(${zoom}) rotate(${rotation}deg)`,
                }}
              />
            </div>

            {/* Image info panel */}
            <div className="absolute bottom-4 left-4 bg-black bg-opacity-70 text-white p-4 rounded-lg max-w-sm">
              <h3 className="font-semibold mb-2">{selectedImage.filename}</h3>
              <div className="space-y-1 text-sm">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4" />
                  <span>{selectedImage.uploadedBy.name} ({selectedImage.uploadedBy.role})</span>
                </div>
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4" />
                  <span>{formatDistanceToNow(selectedImage.uploadedAt, { addSuffix: true })}</span>
                </div>
                {selectedImage.location && (
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    <span>{selectedImage.location.address || `${selectedImage.location.latitude}, ${selectedImage.location.longitude}`}</span>
                  </div>
                )}
                <div className="flex items-center gap-2">
                  <FileImage className="h-4 w-4" />
                  <span>{formatFileSize(selectedImage.size)}</span>
                  {selectedImage.metadata && (
                    <span>• {selectedImage.metadata.width}×{selectedImage.metadata.height}</span>
                  )}
                </div>
              </div>
            </div>

            {/* Image counter */}
            {images.length > 1 && (
              <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-black bg-opacity-70 text-white px-3 py-1 rounded-full text-sm">
                {selectedImageIndex! + 1} of {images.length}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
};
