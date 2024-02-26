export const shake = (element, duration = 90, intensity = 25, iterations = 6) => {
    console.log('test from shake function')
    console.log('element', element)
    // Get original position for accurate return
    const originalPosition = element.getBoundingClientRect();

    // Get the viewport dimensions
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    // Create the keyframes
    const keyframes = [
        { transform: `translate(${intensity}px, ${intensity}px)` },
        { transform: `translate(-${intensity}px, -${intensity}px)` },
        { transform: `translate(-${intensity}px, ${intensity}px)` },
        { transform: `translate(${intensity}px, -${intensity}px)` },
    ];

    // Create the timing options
    const timing = {
        duration,
        iterations,
    };

    // Create the animation
    const animation = element.animate(keyframes, timing);

    // When the animation is complete, return the element to its original position
    animation.onfinish = () => {
        element.style.transform = `translate(${originalPosition.left}px, ${originalPosition.top}px)`;
    };

    // Return the animation

    return animation;



}