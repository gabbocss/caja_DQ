/** PM2: pm2 start ecosystem.config.cjs */
module.exports = {
  apps: [
    {
      name: 'reservas-central',
      script: 'server.js',
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '200M',
      env: {
        NODE_ENV: 'production',
        PORT: '8888',
        HOST: '0.0.0.0',
        DATA_DIR: './data',
        // Preferible: definir en .env o pm2 ecosystem con secretos reales.
        DATABASE_URL:
          process.env.DATABASE_URL ||
          'postgresql://caja:caja@127.0.0.1:5432/programa_caja',
      },
    },
  ],
};
