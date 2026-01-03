package backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

/**
 * This is the entry point for the API Server.
 * Run this 'main' method to start the backend on http://localhost:8080
 */
@SpringBootApplication
@ComponentScan(basePackages = {"backend", "com.imageapp"}) // Include advanced image APIs
public class ImageInverterApplication {

    public static void main(String[] args) {
        SpringApplication.run(ImageInverterApplication.class, args);
        System.out.println("=============================================================");
        System.out.println("✅ SERVER STARTED: http://localhost:8080/api/images/invert");
        System.out.println("   (Keep this running while using the Swing App)");
        System.out.println("=============================================================");
    }
}