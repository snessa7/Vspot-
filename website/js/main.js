// Vspot Landing Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    
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
    
    // Download button functionality
    const downloadBtn = document.getElementById('downloadBtn');
    if (downloadBtn) {
        downloadBtn.addEventListener('click', function(e) {
            e.preventDefault();
            // Replace with actual Mac App Store URL when available
            const appStoreURL = 'https://apps.apple.com/app/vspot/id123456789'; // Placeholder
            
            // For now, show an alert since the app isn't in the store yet
            alert('Vspot will be available on the Mac App Store soon! \n\nFor early access or updates, please contact support@vspot.app');
            
            // Uncomment this line when the app is live in the App Store:
            // window.open(appStoreURL, '_blank');
        });
    }
    
    // Intersection Observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
            }
        });
    }, observerOptions);
    
    // Observe elements for animation
    document.querySelectorAll('.feature-card, .screenshot-item, .problem-item').forEach(el => {
        observer.observe(el);
    });
    
    // Add parallax effect to hero background
    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        const heroBackground = document.querySelector('.hero-background');
        
        if (heroBackground) {
            const rate = scrolled * -0.5;
            heroBackground.style.transform = `translateY(${rate}px)`;
        }
    });
    
    // Screenshot modal functionality
    const screenshots = document.querySelectorAll('.screenshot');
    screenshots.forEach(screenshot => {
        screenshot.addEventListener('click', function() {
            openScreenshotModal(this.src, this.alt);
        });
    });
    
    function openScreenshotModal(src, alt) {
        // Create modal overlay
        const modal = document.createElement('div');
        modal.className = 'screenshot-modal';
        modal.innerHTML = `
            <div class="modal-overlay">
                <div class="modal-content">
                    <button class="modal-close">&times;</button>
                    <img src="${src}" alt="${alt}" class="modal-image">
                    <p class="modal-caption">${alt}</p>
                </div>
            </div>
        `;
        
        // Add modal styles
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.95);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            backdrop-filter: blur(10px);
        `;
        
        const modalContent = modal.querySelector('.modal-content');
        modalContent.style.cssText = `
            position: relative;
            max-width: 90vw;
            max-height: 90vh;
            text-align: center;
        `;
        
        const modalImage = modal.querySelector('.modal-image');
        modalImage.style.cssText = `
            max-width: 100%;
            max-height: 80vh;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        `;
        
        const modalClose = modal.querySelector('.modal-close');
        modalClose.style.cssText = `
            position: absolute;
            top: -40px;
            right: 0;
            background: none;
            border: none;
            font-size: 2rem;
            color: white;
            cursor: pointer;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(139, 92, 246, 0.8);
            display: flex;
            align-items: center;
            justify-content: center;
        `;
        
        const modalCaption = modal.querySelector('.modal-caption');
        modalCaption.style.cssText = `
            color: #CBD5E1;
            margin-top: 1rem;
            font-size: 1rem;
        `;
        
        document.body.appendChild(modal);
        
        // Close modal functionality
        function closeModal() {
            document.body.removeChild(modal);
        }
        
        modalClose.addEventListener('click', closeModal);
        modal.addEventListener('click', function(e) {
            if (e.target === modal || e.target.className === 'modal-overlay') {
                closeModal();
            }
        });
        
        // Close with Escape key
        document.addEventListener('keydown', function escapeHandler(e) {
            if (e.key === 'Escape') {
                closeModal();
                document.removeEventListener('keydown', escapeHandler);
            }
        });
    }
    
    // Add loading state for images
    const images = document.querySelectorAll('img');
    images.forEach(img => {
        img.addEventListener('load', function() {
            this.style.opacity = '1';
        });
        
        // Set initial opacity for loading effect
        img.style.opacity = '0';
        img.style.transition = 'opacity 0.3s ease';
    });
    
    // Performance optimization: Lazy load images
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src || img.src;
                    img.classList.remove('lazy');
                    imageObserver.unobserve(img);
                }
            });
        });
        
        document.querySelectorAll('img[data-src]').forEach(img => {
            imageObserver.observe(img);
        });
    }
});