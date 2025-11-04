package com.cataloging.userapi.repository;

import com.cataloging.userapi.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByProviderAndProviderId(String provider, String providerId);
    
    Optional<User> findByEmail(String email);
    
    boolean existsByProviderAndProviderId(String provider, String providerId);
}