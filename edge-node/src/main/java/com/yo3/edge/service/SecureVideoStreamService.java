package com.yo3.edge.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * FLUXO VERMELHO (Red Flow): Video Secure Streaming Service
 * 
 * Responsabilidades:
 * - Capturar buffer de vídeo bruto do VLCj
 * - Enviar stream criptografado ao Microkernel via HTTP chunked
 * - Não armazenar nada localmente (Zero-Trust)
 */
@Service
public class SecureVideoStreamService {
    
    private static final Logger logger = LoggerFactory.getLogger(SecureVideoStreamService.class);
    
    private static final int CHUNK_SIZE = 64 * 1024; // 64KB chunks
    private static final int BUFFER_SIZE = 256 * 1024; // 256KB buffer
    
    @Value("${microkernel.url}")
    private String microkernelUrl;
    
    private HttpURLConnection currentConnection;
    private OutputStream currentOutputStream;
    private String currentSessionId;
    private AtomicLong totalBytesSent = new AtomicLong(0);
    
    /**
     * Inicia uma sessão de streaming seguro
     * @param cameraId Identificador da câmera
     * @return ID da sessão criada
     */
    public String startSecureStream(String cameraId) throws IOException {
        currentSessionId = UUID.randomUUID().toString();
        
        logger.info("🔴 FLUXO VERMELHO: Iniciando stream seguro - Camera: {}, Session: {}", 
                    cameraId, currentSessionId);
        
        // Cria conexão HTTP com Microkernel
        URL url = new URL(microkernelUrl + "/stream/encrypt");
        currentConnection = (HttpURLConnection) url.openConnection();
        
        // Configuração para Chunked Transfer Encoding
        currentConnection.setDoOutput(true);
        currentConnection.setRequestMethod("POST");
        currentConnection.setRequestProperty("Content-Type", "application/octet-stream");
        currentConnection.setRequestProperty("X-Session-ID", currentSessionId);
        currentConnection.setRequestProperty("X-Camera-ID", cameraId);
        currentConnection.setRequestProperty("Transfer-Encoding", "chunked");
        currentConnection.setChunkedStreamingMode(CHUNK_SIZE);
        
        // Abre stream de saída
        currentOutputStream = new BufferedOutputStream(
            currentConnection.getOutputStream(), 
            BUFFER_SIZE
        );
        
        totalBytesSent.set(0);
        
        logger.info("✓ Stream seguro estabelecido com Microkernel");
        return currentSessionId;
    }
    
    /**
     * Envia um chunk de vídeo para o Microkernel
     * @param videoBuffer Buffer contendo dados de vídeo bruto
     * @param offset Offset no buffer
     * @param length Tamanho dos dados
     */
    public void sendVideoChunk(byte[] videoBuffer, int offset, int length) throws IOException {
        if (currentOutputStream == null) {
            throw new IllegalStateException("Stream não iniciado. Chame startSecureStream() primeiro.");
        }
        
        // Envia chunk
        currentOutputStream.write(videoBuffer, offset, length);
        currentOutputStream.flush();
        
        long totalSent = totalBytesSent.addAndGet(length);
        
        if (totalSent % (1024 * 1024) == 0) { // Log a cada 1MB
            logger.debug("📤 Enviado: {} MB", totalSent / (1024 * 1024));
        }
    }
    
    /**
     * Envia buffer completo (sobrecarga de conveniência)
     */
    public void sendVideoChunk(ByteBuffer buffer) throws IOException {
        byte[] array = new byte[buffer.remaining()];
        buffer.get(array);
        sendVideoChunk(array, 0, array.length);
    }
    
    /**
     * Finaliza o stream e obtém a chave do storage
     * @return Storage reference key do blob criptografado
     */
    public String finalizeStream() throws IOException {
        if (currentOutputStream == null) {
            throw new IllegalStateException("Nenhum stream ativo");
        }
        
        try {
            // Fecha stream de saída
            currentOutputStream.flush();
            currentOutputStream.close();
            
            // Lê resposta do Microkernel
            int responseCode = currentConnection.getResponseCode();
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader reader = new BufferedReader(
                    new InputStreamReader(currentConnection.getInputStream())
                );
                
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                
                // Extrai storage key da resposta JSON
                String storageKey = extractStorageKey(response.toString());
                
                logger.info("✓ Stream finalizado. Total enviado: {} MB, Storage Key: {}", 
                           totalBytesSent.get() / (1024 * 1024), storageKey);
                
                return storageKey;
            } else {
                logger.error("❌ Erro no Microkernel: HTTP {}", responseCode);
                throw new IOException("Microkernel retornou erro: " + responseCode);
            }
            
        } finally {
            cleanup();
        }
    }
    
    /**
     * Cancela o stream atual
     */
    public void cancelStream() {
        logger.warn("⚠️ Stream cancelado: {}", currentSessionId);
        cleanup();
    }
    
    /**
     * Limpa recursos da conexão
     */
    private void cleanup() {
        try {
            if (currentOutputStream != null) {
                currentOutputStream.close();
            }
        } catch (IOException e) {
            logger.error("Erro ao fechar stream", e);
        }
        
        if (currentConnection != null) {
            currentConnection.disconnect();
        }
        
        currentOutputStream = null;
        currentConnection = null;
        currentSessionId = null;
    }
    
    /**
     * Extrai storage key da resposta JSON
     */
    private String extractStorageKey(String jsonResponse) {
        // Parsing simples (substituir por Jackson em produção)
        int keyIndex = jsonResponse.indexOf("\"storageKey\"");
        if (keyIndex == -1) {
            keyIndex = jsonResponse.indexOf("\"storage_key\"");
        }
        
        if (keyIndex != -1) {
            int start = jsonResponse.indexOf("\"", keyIndex + 13) + 1;
            int end = jsonResponse.indexOf("\"", start);
            return jsonResponse.substring(start, end);
        }
        
        logger.warn("Storage key não encontrada na resposta. Usando session ID como fallback.");
        return currentSessionId;
    }
    
    /**
     * Retorna estatísticas do stream atual
     */
    public StreamStats getStats() {
        return new StreamStats(
            currentSessionId,
            totalBytesSent.get(),
            currentOutputStream != null
        );
    }
    
    /**
     * Inner class para estatísticas
     */
    public static class StreamStats {
        public final String sessionId;
        public final long bytesSent;
        public final boolean isActive;
        
        public StreamStats(String sessionId, long bytesSent, boolean isActive) {
            this.sessionId = sessionId;
            this.bytesSent = bytesSent;
            this.isActive = isActive;
        }
    }
}
