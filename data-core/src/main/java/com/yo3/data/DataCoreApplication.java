package com.yo3.data;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * yo3 Data Core - Secure I/O Engine
 * 
 * Responsibilities:
 * - Receive video streams from Edge Node
 * - Process in real-time (AES-256-GCM)
 * - Store protected blobs (blind storage)
 * - Serve processed blobs to authorized clients
 */
@SpringBootApplication
public class DataCoreApplication {
    
    private static final Logger logger = LoggerFactory.getLogger(DataCoreApplication.class);
    
    public static void main(String[] args) {
        logger.info("═══════════════════════════════════════════════════");
        logger.info("🔒 DATA CORE MICROKERNEL - Zero-Trust Video System");
        logger.info("═══════════════════════════════════════════════════");
        
        SpringApplication.run(DataCoreApplication.class, args);
        
        logger.info("✓ Microkernel pronto para receber streams processados");
    }
}
