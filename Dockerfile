# Use Nginx to serve the static content
FROM nginx:alpine

# Copy the build artifacts from the host to the container
COPY build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
