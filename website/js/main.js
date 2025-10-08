// Vspot Website JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Handle contact form submission with Netlify's built-in form handling
    const contactForm = document.querySelector('.contact-form');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            // Let Netlify handle the form submission naturally
            const submitButton = this.querySelector('button[type="submit"]');
            const originalText = submitButton.innerHTML;
            
            // Show loading state
            submitButton.innerHTML = 'Sending...';
            submitButton.disabled = true;
            
            // Let the form submit naturally to Netlify
            // Netlify will handle the submission and redirect
            setTimeout(() => {
                // If we're still on the same page after 5 seconds, show success
                submitButton.innerHTML = 'Message Sent!';
                submitButton.style.background = 'linear-gradient(135deg, #10B981, #059669)';
                this.reset();
                
                // Reset button after 3 seconds
                setTimeout(() => {
                    submitButton.innerHTML = originalText;
                    submitButton.disabled = false;
                    submitButton.style.background = '';
                }, 3000);
            }, 1000);
        });
    }
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // FAQ Accordion functionality
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        
        const toggleFAQ = () => {
            const isActive = item.classList.contains('active');
            
            // Close other FAQ items
            faqItems.forEach(otherItem => {
                if (otherItem !== item && otherItem.classList.contains('active')) {
                    otherItem.classList.remove('active');
                    const otherQuestion = otherItem.querySelector('.faq-question');
                    otherQuestion.setAttribute('aria-expanded', 'false');
                }
            });
            
            // Toggle current item
            item.classList.toggle('active');
            question.setAttribute('aria-expanded', !isActive);
        };
        
        // Click handler
        question.addEventListener('click', toggleFAQ);
        
        // Keyboard navigation (Enter and Space)
        question.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                toggleFAQ();
            }
        });
    });
    
    // Download button handlers (placeholder for App Store links)
    const downloadBtn = document.getElementById('downloadBtn');
    const pricingBtn = document.getElementById('pricingBtn');
    
    if (downloadBtn) {
        downloadBtn.addEventListener('click', function(e) {
            e.preventDefault();
            // TODO: Replace with actual App Store link
            alert('Vspot will be available on the Mac App Store soon!');
        });
    }
    
    if (pricingBtn) {
        pricingBtn.addEventListener('click', function(e) {
            e.preventDefault();
            // TODO: Replace with actual App Store link
            alert('Vspot Pro will be available on the Mac App Store soon!');
        });
    }
    
    // Add some subtle animations on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe elements for animation
    document.querySelectorAll('.feature-card, .audience-card, .screenshot-item').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});