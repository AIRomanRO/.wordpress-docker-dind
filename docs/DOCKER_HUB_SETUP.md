# Docker Hub Setup for GitHub Actions

This guide explains how to configure Docker Hub credentials for the GitHub Actions workflow to automatically build and push Docker images.

## Prerequisites

- A Docker Hub account (create one at https://hub.docker.com if you don't have one)
- Admin access to this GitHub repository
- The Docker Hub repository `airoman/wp-dind` created

## Step 1: Create Docker Hub Access Token

1. **Login to Docker Hub**
   - Go to https://hub.docker.com
   - Sign in with your credentials

2. **Navigate to Access Tokens**
   - Click on your username in the top-right corner
   - Select **"Account Settings"**
   - Click on **"Security"** in the left sidebar
   - Click on **"New Access Token"**

3. **Create New Token**
   - **Access Token Description**: Enter a name like `github-actions-wp-dind`
   - **Access permissions**: Select **"Read, Write, Delete"** (or "Read & Write" if that's the only option)
   - Click **"Generate"**

4. **Copy the Token**
   - ⚠️ **IMPORTANT**: Copy the token immediately and save it securely
   - You won't be able to see it again after closing the dialog
   - The token looks like: `dckr_pat_aBcDeFgHiJkLmNoPqRsTuVwXyZ123456`

## Step 2: Add Secrets to GitHub Repository

1. **Navigate to Repository Settings**
   - Go to your GitHub repository: https://github.com/YOUR_USERNAME/wordpress-docker-dind
   - Click on **"Settings"** tab (top menu)

2. **Access Secrets and Variables**
   - In the left sidebar, expand **"Secrets and variables"**
   - Click on **"Actions"**

3. **Add Docker Hub Username**
   - Click **"New repository secret"**
   - **Name**: `DOCKER_HUB_USERNAME`
   - **Secret**: Enter your Docker Hub username (e.g., `airoman`)
   - Click **"Add secret"**

4. **Add Docker Hub Token**
   - Click **"New repository secret"** again
   - **Name**: `DOCKER_HUB_TOKEN`
   - **Secret**: Paste the access token you copied in Step 1
   - Click **"Add secret"**

## Step 3: Verify Secrets

After adding both secrets, you should see:

```
DOCKER_HUB_USERNAME
DOCKER_HUB_TOKEN
```

in the "Repository secrets" section.

## Step 4: Create Docker Hub Repository (if not exists)

1. **Login to Docker Hub**
   - Go to https://hub.docker.com

2. **Create Repository**
   - Click **"Create Repository"**
   - **Name**: `wp-dind`
   - **Namespace**: Select your username (e.g., `airoman`)
   - **Visibility**: Choose **Public** or **Private**
   - **Description**: "WordPress Docker-in-Docker images with multiple PHP and MySQL versions"
   - Click **"Create"**

3. **Verify Repository**
   - Your repository should be accessible at: `https://hub.docker.com/r/airoman/wp-dind`

## How to Use the GitHub Actions Workflow

### Scenario 1: Build and Push All Images

1. Create a Pull Request with your changes
2. Add the label **`build-images`** to the PR
3. Add the label **`push-images`** to the PR
4. Merge the PR
5. GitHub Actions will:
   - Build all Docker images
   - Push all images to Docker Hub

### Scenario 2: Build All Images (No Push)

1. Create a Pull Request with your changes
2. Add the label **`build-images`** to the PR
3. Merge the PR
4. GitHub Actions will:
   - Build all Docker images
   - NOT push to Docker Hub (useful for testing)

### Scenario 3: Build and Push Only Changed Images

1. Create a Pull Request with changes to specific image directories (e.g., `images/php/8.3/`)
2. Add the label **`build-images`** to the PR
3. Add the label **`push-images`** to the PR
4. Merge the PR
5. GitHub Actions will:
   - Detect which images changed
   - Build only the changed images
   - Push only the changed images to Docker Hub

### Scenario 4: Build Only Changed Images (No Push)

1. Create a Pull Request with changes to specific image directories
2. Add the label **`build-images`** to the PR
3. Merge the PR
4. GitHub Actions will:
   - Detect which images changed
   - Build only the changed images
   - NOT push to Docker Hub

### Scenario 5: Automatic Detection (No Labels)

1. Create a Pull Request with changes to image directories
2. Merge the PR (without any labels)
3. GitHub Actions will:
   - Detect which images changed
   - Build only the changed images
   - NOT push to Docker Hub

## Important Rules

- ✅ **`build-images`** label can be used alone
- ✅ **`build-images`** + **`push-images`** labels can be used together
- ❌ **`push-images`** label CANNOT be used without **`build-images`** label
- ✅ If no labels are added, only changed images will be built (no push)
- ✅ Changes are detected automatically by comparing files in the PR

## Troubleshooting

### Error: "Invalid username or password"

- Verify that `DOCKER_HUB_USERNAME` is your Docker Hub username (not email)
- Verify that `DOCKER_HUB_TOKEN` is the access token (not your password)
- Make sure the token has "Read & Write" permissions

### Error: "denied: requested access to the resource is denied"

- Verify that the Docker Hub repository `airoman/wp-dind` exists
- Verify that your Docker Hub account has write access to the repository
- Check that the token has the correct permissions

### Error: "push-images requires build-images"

- You added the `push-images` label without the `build-images` label
- Add both labels to the PR

### Workflow doesn't run

- Make sure the PR is merged (not just closed)
- Check that the PR was merged to the `main` branch
- Verify the workflow file is in `.github/workflows/build-push-images.yml`

## Security Best Practices

1. **Never commit tokens to the repository**
   - Always use GitHub Secrets
   - Never hardcode credentials in workflow files

2. **Use Access Tokens instead of passwords**
   - Access tokens can be revoked without changing your password
   - Tokens can have limited permissions

3. **Rotate tokens periodically**
   - Create a new token every 6-12 months
   - Delete old tokens after replacing them

4. **Limit token permissions**
   - Only grant "Read & Write" permissions (not "Admin")
   - Create separate tokens for different purposes

## Monitoring

### View Workflow Runs

1. Go to your GitHub repository
2. Click on the **"Actions"** tab
3. Select **"Build and Push Docker Images"** workflow
4. View individual runs to see:
   - Which images were built
   - Which images were pushed
   - Build logs and errors

### View Docker Hub Images

1. Go to https://hub.docker.com/r/airoman/wp-dind
2. Click on **"Tags"** to see all pushed images
3. Verify that images have the correct tags (e.g., `mysql-8.0.40`, `php-8.3.14`)

## Additional Resources

- [Docker Hub Access Tokens Documentation](https://docs.docker.com/docker-hub/access-tokens/)
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions Docker Login](https://github.com/docker/login-action)

