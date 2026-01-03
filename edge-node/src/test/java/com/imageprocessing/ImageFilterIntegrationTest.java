package com.imageprocessing;

import backend.ImageInverterApplication;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.imageapp.service.BatchImageProcessor;
import java.util.List;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(classes = ImageInverterApplication.class)
@AutoConfigureMockMvc
public class ImageFilterIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMultipartFile createTestImage() throws Exception {
        BufferedImage img = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);

        return new MockMultipartFile(
            "file",
            "test.jpg",
            "image/jpeg",
            baos.toByteArray()
        );
    }

    @Test
    void testGrayscaleFilter() throws Exception {
        MockMultipartFile file = createTestImage();

        mockMvc.perform(multipart("/api/images/filter/grayscale")
            .file(file))
            .andExpect(status().isOk());
    }

    @Test
    void testBlurFilter() throws Exception {
        MockMultipartFile file = createTestImage();

        mockMvc.perform(multipart("/api/images/filter/blur")
            .file(file)
            .param("radius", "5"))
            .andExpect(status().isOk());
    }

    @Test
    void testBrightnessFilter() throws Exception {
        MockMultipartFile file = createTestImage();

        mockMvc.perform(multipart("/api/images/filter/brightness")
            .file(file)
            .param("factor", "1.2"))
            .andExpect(status().isOk());
    }

    @Test
    void testBatchProcess() throws Exception {
        byte[] imageBytes = createTestImage().getBytes();
        BatchImageProcessor.BatchRequest request = new BatchImageProcessor.BatchRequest();
        request.operation = "grayscale";
        BatchImageProcessor.ImageData image = new BatchImageProcessor.ImageData();
        image.id = "img-1";
        image.format = "png";
        image.imageBytes = imageBytes;
        request.images = List.of(image);

        mockMvc.perform(post("/api/images/batch-process")
            .contentType("application/json")
            .content(objectMapper.writeValueAsBytes(request)))
            .andExpect(status().isOk());
    }

    @Test
    void testFiltersList() throws Exception {
        mockMvc.perform(get("/api/images/filters"))
            .andExpect(status().isOk());
    }
}
