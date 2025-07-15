import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  Camera,
  Eye,
  Download,
  MoreHorizontal,
  Clock,
  User
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

interface ImagePreviewProps {
  images: EmergencyImage[];
  maxPreview?: number;
  onViewAll?: () => void;
  onImageClick?: (imageIndex: number) => void;
}

export const ImagePreview: React.FC<ImagePreviewProps> = ({
  images,
  maxPreview = 4,
  onViewAll,
  onImageClick,
}) => {
  const previewImages = images.slice(0, maxPreview);
  const remainingCount = Math.max(0, images.length - maxPreview);

  if (images.length === 0) {
    return (
      <Card className="border-0 shadow-lg">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Camera className="h-5 w-5 text-blue-500" />
            Emergency Images
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <Camera className="h-12 w-12 text-gray-400 mx-auto mb-3" />
            <p className="text-gray-500 text-sm">No images available</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Camera className="h-5 w-5 text-blue-500" />
            Emergency Images
            <Badge variant="outline" className="ml-2">
              {images.length}
            </Badge>
          </CardTitle>
          {images.length > maxPreview && (
            <Button 
              variant="outline" 
              size="sm" 
              onClick={onViewAll}
              className="cursor-pointer"
            >
              <Eye className="h-4 w-4 mr-2" />
              View All
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-3">
          {previewImages.map((image, index) => (
            <div
              key={image.id}
              className="group relative aspect-video bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:shadow-md transition-all duration-300"
              onClick={() => onImageClick?.(index)}
            >
              <img
                src={image.thumbnail}
                alt={image.filename}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />
              
              {/* Overlay */}
              <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all duration-300 flex items-center justify-center">
                <Eye className="h-5 w-5 text-white opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </div>
              
              {/* Image info */}
              <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-2">
                <div className="text-white text-xs">
                  <div className="flex items-center gap-1 mb-1">
                    <User className="h-3 w-3" />
                    <span className="truncate">{image.uploadedBy.name}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    <span>{formatDistanceToNow(image.uploadedAt, { addSuffix: true })}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
          
          {/* Show remaining count if there are more images */}
          {remainingCount > 0 && (
            <div
              className="group relative aspect-video bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:shadow-md transition-all duration-300 flex items-center justify-center"
              onClick={onViewAll}
            >
              <div className="text-center">
                <MoreHorizontal className="h-8 w-8 text-gray-400 mx-auto mb-2 group-hover:text-gray-600 transition-colors" />
                <p className="text-gray-600 font-medium">+{remainingCount} more</p>
                <p className="text-gray-500 text-xs">Click to view all</p>
              </div>
            </div>
          )}
        </div>
        
        {/* Quick actions */}
        <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
          <div className="text-sm text-gray-600">
            {images.length} image{images.length !== 1 ? 's' : ''} • Latest: {formatDistanceToNow(images[0]?.uploadedAt || new Date(), { addSuffix: true })}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" className="cursor-pointer">
              <Download className="h-4 w-4 mr-2" />
              Download All
            </Button>
            {images.length > maxPreview && (
              <Button 
                variant="outline" 
                size="sm" 
                onClick={onViewAll}
                className="cursor-pointer"
              >
                View Gallery
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
