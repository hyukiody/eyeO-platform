package com.yo3.edge.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Exports video frames to Data-Core Microkernel for encoding
 * Implements Zero-Trust architecture - no local encoding
 */
@Service
public class VideoStreamExportService {
    
    private static final Logger logger = LoggerFactory.getLogger(VideoStreamExportService.class);
    
    @Value("${microkernel.url:http://localhost:9090}")
    private String microkernelUrl;
    
    @Value("${device.token:default-dev-token}")
    private String deviceToken;
    
    private final RestTemplate restTemplate;
    
    public VideoStreamExportService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    /**
     * Send raw video frame to Microkernel for encoding
     * @param frameData Raw video frame bytes
     * @param frameId Unique frame identifier
     * @return Encoded frame reference ID
     */
    public String exportFrameForEncoding(byte[] frameData, String frameId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.set("X-Frame-ID", frameId);
            headers.set("X-Device-Token", deviceToken);
            
            HttpEntity<byte[]> request = new HttpEntity<>(frameData, headers);
            
            String endpoint = microkernelUrl + "/api/stream/encode";
            
            logger.debug("Exporting frame {} to Microkernel: {}", frameId, endpoint);
            
            ResponseEntity<String> response = restTemplate.postForEntity(
                endpoint,
                request,
                String.class
            );
            
            if (response.getStatusCode().is2xxSuccessful()) {
                String referenceId = response.getBody();
                logger.info("Frame {} encoded successfully. Reference: {}", frameId, referenceId);
                return referenceId;
            } else {
                logger.error("Microkernel returned status: {}", response.getStatusCode());
                throw new VideoExportException("Encoding failed with status: " + response.getStatusCode());
            }
            
        } catch (Exception e) {
            logger.error("Failed to export frame {} to Microkernel", frameId, e);
            throw new VideoExportException("Frame export failed: " + e.getMessage(), e);
        }
    }
    
    /**
     * Batch export for video segments
     */
    public String exportVideoSegment(Path videoSegmentPath, String segmentId) throws IOException {
        byte[] segmentData = Files.readAllBytes(videoSegmentPath);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        headers.set("X-Segment-ID", segmentId);
        headers.set("X-Device-Token", deviceToken);
        
        HttpEntity<byte[]> request = new HttpEntity<>(segmentData, headers);
        
        String endpoint = microkernelUrl + "/api/stream/encode/segment";
        
        ResponseEntity<String> response = restTemplate.postForEntity(
            endpoint,
            request,
            String.class
        );
        
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new VideoExportException("Segment export failed: " + response.getStatusCode());
        }
        
        logger.info("Video segment {} exported successfully", segmentId);
        return response.getBody();
    }
    
    public static class VideoExportException extends RuntimeException {
        public VideoExportException(String message) {
            super(message);
        }
        
        public VideoExportException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
