<template>
    <div v-if="showPopup" class="popup">
        <!-- Your popup content here -->
        <button @click="closePopup">Close</button>
        <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam
            pulvinar risus non risus hendrerit venenatis. Pellentesque sit amet
            hendrerit risus, sed porttitor quam.
        </p>
    </div>
</template>

<script>
export default {
    data() {
        return {
            showPopup: false,
        };
    },
    methods: {
        openPopup() {
            this.showPopup = true;
            console.log('openPopup')
        },
        closePopup() {
            this.showPopup = false;
        },
    },
};
</script>
  
<style>
.popup {
    /* Your popup styles here */
    position: fixed;
    top: 0;
    left: 0;
    width: 50%;
    height: 50%;

}
</style>