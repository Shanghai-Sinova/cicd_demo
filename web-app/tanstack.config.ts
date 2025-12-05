import { defineConfig } from '@tanstack/react-start/config';

export default defineConfig({
  ssr: true,
  server: {
    port: 5003,
    host: '0.0.0.0',
  },
});
