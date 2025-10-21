#!/bin/bash
set -e

echo "🚀 Setting up production environment..."

# Create .env.production if it doesn't exist
if [ ! -f .env.production ]; then
    echo "📝 Creating .env.production from example..."
    cat > .env.production << 'EOF'
NODE_ENV=production
PORT=3000
HOSTNAME=0.0.0.0
NEXT_TELEMETRY_DISABLED=1
EOF
    echo "✅ .env.production created"
else
    echo "✅ .env.production already exists"
fi

# Create SSL directory for nginx
if [ ! -d ssl ]; then
    echo "📁 Creating SSL directory..."
    mkdir -p ssl
    echo "✅ SSL directory created"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "Quick commands:"
echo "  make up          - Start single instance"
echo "  make prod-up     - Start with nginx load balancer"
echo "  make prod-scale N=5 - Scale to 5 instances"
echo "  make logs        - View logs"
echo "  make help        - Show all commands"

