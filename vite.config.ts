import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
    server: {
        host: '0.0.0.0',
        port: Number(process.env.PORT) || 3000,  // Porta que o Vite vai escutar
    },
});
