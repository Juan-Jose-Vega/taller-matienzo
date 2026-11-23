import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { viteSingleFile } from 'vite-plugin-singlefile';

// El resultado de "npm run build" es UN solo archivo (dist/index.html) que se abre con doble clic,
// sin servidor: por eso se incrusta todo el JS y el CSS y se usa el enrutador con "#".
export default defineConfig({
  base: './',
  plugins: [vue(), viteSingleFile()],
  build: { target: 'es2019', cssCodeSplit: false, chunkSizeWarningLimit: 2000 },
});
