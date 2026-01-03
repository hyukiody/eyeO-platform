package com.yo3.edge.service;

import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.UUID;

/**
 * Processes video frames and exports to Microkernel
 * NO LOCAL ENCODING - Zero-Trust architecture
 */
@Service
public class ZeroTrustVideoProcessor {
    
    private static final Logger logger = LoggerFactory.getLogger(ZeroTrustVideoProcessor.class);
    
    private final VideoStreamExportService exportService;
    private final ObjectDetectionService detectionService;
    
    public ZeroTrustVideoProcessor(VideoStreamExportService exportService, 
                                   ObjectDetectionService detectionService) {
        this.exportService = exportService;
        this.detectionService = detectionService;
    }
    
    /**
     * Process frame: detect objects, then export to Microkernel for encoding
     * NO LOCAL ENCODING - all video data sent to Data-Core
     */
    public ProcessingResult processFrame(BufferedImage frame) {
        try {
            // 1. Run YOLO detection (local inference)
            List<ObjectDetectionService.Detection> detections = detectionService.detectObjects(frame);
            
            // 2. Convert frame to bytes
            byte[] frameBytes = encodeFrame(frame);
            
            // 3. Export to Microkernel for encoding (NO LOCAL ENCODING)
            String frameId = UUID.randomUUID().toString();
            String referenceId = exportService.exportFrameForEncoding(frameBytes, frameId);
            
            logger.info("Frame processed. Detections: {}, Reference: {}", 
                       detections.size(), referenceId);
            
            return new ProcessingResult(frameId, referenceId, detections);
            
        } catch (Exception e) {
            logger.error("Frame processing failed", e);
            throw new ProcessingException("Failed to process frame", e);
        }
    }

    private byte[] encodeFrame(BufferedImage frame) throws IOException {
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            ImageIO.write(frame, "jpg", outputStream);
            return outputStream.toByteArray();
        }
    }
    
    /**
     * Result of frame processing
     */
    public static class ProcessingResult {
        private final String frameId;
        private final String encodedReferenceId;
        private final List<ObjectDetectionService.Detection> detections;
        
        public ProcessingResult(String frameId, String encodedReferenceId, List<ObjectDetectionService.Detection> detections) {
            this.frameId = frameId;
            this.encodedReferenceId = encodedReferenceId;
            this.detections = detections;
        }
        
        public String getFrameId() { return frameId; }
        public String getEncodedReferenceId() { return encodedReferenceId; }
        public List<ObjectDetectionService.Detection> getDetections() { return detections; }
    }
    
    public static class ProcessingException extends RuntimeException {
        public ProcessingException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
