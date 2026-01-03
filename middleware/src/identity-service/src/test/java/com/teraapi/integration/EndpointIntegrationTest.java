package com.teraapi.integration;

import com.teraapi.identity.dto.AuthenticationRequest;
import com.teraapi.identity.dto.AuthenticationResponse;
import com.teraapi.identity.entity.Role;
import com.teraapi.identity.entity.User;
import com.teraapi.identity.repository.RoleRepository;
import com.teraapi.identity.repository.UserRepository;
import com.teraapi.identity.service.AuthenticationService;
import com.teraapi.identity.service.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EndpointIntegrationTest {

    private static final String TEST_SECRET =
            "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";

    private JwtTokenProvider realTokenProvider;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AuthenticationService authenticationService;

    @BeforeEach
    void setUp() {
        realTokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(realTokenProvider, "jwtSecret", TEST_SECRET);
        ReflectionTestUtils.setField(realTokenProvider, "jwtExpirationMs", 3_600_000L);

        authenticationService = new AuthenticationService(
                authenticationManager,
                jwtTokenProvider,
                userRepository,
                roleRepository,
                passwordEncoder
        );
    }

    @Test
    void shouldGenerateValidJwtWithCustomClaims() {
        String token = realTokenProvider.generateToken("neo", "ADMIN", "device-77");

        assertTrue(realTokenProvider.isTokenValid(token));
        assertEquals("neo", realTokenProvider.getUsernameFromToken(token));
        assertEquals("ADMIN", realTokenProvider.getRoleFromToken(token));
        assertEquals("device-77", realTokenProvider.getDeviceIdFromToken(token));
    }

    @Test
    void shouldRejectMalformedTokens() {
        assertFalse(realTokenProvider.isTokenValid("this-is-not-a-jwt"));
    }

    @Test
    void shouldAuthenticateUserAndReturnJwtResponse() {
        AuthenticationRequest request = AuthenticationRequest.builder()
                .username("trinity")
                .password("matrix")
                .build();

        Role role = Role.builder()
                .id(1L)
                .name("DEFENDER")
                .description("Zero-trust defender")
                .build();

        User user = User.builder()
                .id(5L)
                .username("trinity")
                .password("hash")
                .role(role)
                .deviceId("device-99")
                .build();

        when(authenticationManager.authenticate(any())).thenReturn(mock(Authentication.class));
        when(userRepository.findByUsername("trinity")).thenReturn(Optional.of(user));
        when(jwtTokenProvider.generateToken("trinity", "DEFENDER", "device-99"))
                .thenReturn("signed-token");
        when(jwtTokenProvider.getExpirationTimeInSeconds()).thenReturn(3600L);

        AuthenticationResponse response = authenticationService.authenticate(request);

        assertEquals("signed-token", response.getAccessToken());
        assertEquals("trinity", response.getUsername());
        assertEquals("DEFENDER", response.getRole());
        assertEquals(3600L, response.getExpiresIn());
        assertEquals("Bearer", response.getTokenType());

        verify(authenticationManager).authenticate(
                argThat(auth -> "trinity".equals(auth.getName()))
        );
        verify(jwtTokenProvider).generateToken("trinity", "DEFENDER", "device-99");
    }

    @Test
    void shouldRegisterNewUserWithEncodedPasswordAndDefaultRole() {
        User newUser = User.builder()
                .username("switch")
                .password("plain-password")
                .email("switch@zion.io")
                .deviceId("device-17")
                .build();

        Role userRole = Role.builder()
                .id(2L)
                .name("USER")
                .description("Standard user")
                .build();

        when(userRepository.findByUsername("switch")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("switch@zion.io")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("plain-password")).thenReturn("encoded-secret");
        when(roleRepository.findByName("USER")).thenReturn(Optional.of(userRole));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            saved.setId(42L);
            return saved;
        });
        when(jwtTokenProvider.generateToken("switch", "USER"))
                .thenReturn("fresh-token");
        when(jwtTokenProvider.getExpirationTimeInSeconds()).thenReturn(7_200L);

        AuthenticationResponse response = authenticationService.register(newUser);

        assertEquals("fresh-token", response.getAccessToken());
        assertEquals("switch", response.getUsername());
        assertEquals("USER", response.getRole());
        assertEquals(7_200L, response.getExpiresIn());

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());

        User captured = userCaptor.getValue();
        assertEquals("encoded-secret", captured.getPassword());
        assertEquals(userRole, captured.getRole());

        verify(passwordEncoder, times(1)).encode("plain-password");
    }
}
