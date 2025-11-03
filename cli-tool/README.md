# WordPress Docker-in-Docker CLI Tool

A global command-line tool for managing WordPress Docker-in-Docker environments anywhere on your system.

## Installation

### Global Installation

```bash
cd cli-tool
npm install -g .
```

Or install directly from npm (once published):

```bash
npm install -g wp-dind-cli
```

### Verify Installation

```bash
wp-dind --version
```

## Quick Start

1. **Initialize a new WordPress DinD environment:**

```bash
mkdir my-wordpress-project
cd my-wordpress-project
wp-dind init
```

2. **Start the environment:**

```bash
wp-dind start
```

3. **Create a WordPress instance:**

```bash
wp-dind exec instance-manager.sh create mysite 80
```

4. **Start the WordPress instance:**

```bash
wp-dind exec instance-manager.sh start mysite
```

5. **Get instance information:**

```bash
wp-dind exec instance-manager.sh info mysite
```

## Commands

### `wp-dind init`

Initialize a WordPress DinD environment in the current directory.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `--with-phpmyadmin` - Include phpMyAdmin service
- `--with-mailcatcher` - Include MailCatcher service

**Example:**
```bash
wp-dind init --with-phpmyadmin --with-mailcatcher
```

### `wp-dind start`

Start the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind start
```

### `wp-dind stop`

Stop the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind stop
```

### `wp-dind status`

Check the status of the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind status
```

### `wp-dind logs`

View logs from the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `-f, --follow` - Follow log output
- `-s, --service <service>` - Show logs for specific service

**Example:**
```bash
wp-dind logs -f
wp-dind logs -s wordpress-dind
```

### `wp-dind exec <command>`

Execute a command in the DinD container.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Examples:**
```bash
# Create a WordPress instance
wp-dind exec instance-manager.sh create mysite 80

# List all instances
wp-dind exec instance-manager.sh list

# Get instance info
wp-dind exec instance-manager.sh info mysite

# Start an instance
wp-dind exec instance-manager.sh start mysite

# Stop an instance
wp-dind exec instance-manager.sh stop mysite

# View instance logs
wp-dind exec instance-manager.sh logs mysite

# Remove an instance
wp-dind exec instance-manager.sh remove mysite

# Execute any Docker command
wp-dind exec docker ps
wp-dind exec docker images
```

### `wp-dind destroy`

Destroy the WordPress DinD environment (removes all data).

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind destroy
```

## WordPress Instance Management

The `instance-manager.sh` script provides comprehensive WordPress instance management:

### Create Instance

```bash
wp-dind exec instance-manager.sh create <name> [mysql_version]
```

- `name`: Instance name (required)
- `mysql_version`: MySQL version - 56, 57, or 80 (default: 80)

**Example:**
```bash
wp-dind exec instance-manager.sh create mysite 80
```

### Start Instance

```bash
wp-dind exec instance-manager.sh start <name>
```

### Stop Instance

```bash
wp-dind exec instance-manager.sh stop <name>
```

### List Instances

```bash
wp-dind exec instance-manager.sh list
```

### Instance Info

```bash
wp-dind exec instance-manager.sh info <name>
```

Shows detailed information including:
- Database credentials
- Network configuration
- Container status
- Access URL

### View Logs

```bash
wp-dind exec instance-manager.sh logs <name> [service]
```

- `service`: wordpress, mysql, or nginx (optional)

### Remove Instance

```bash
wp-dind exec instance-manager.sh remove <name>
```

## Use Cases

### Multiple Projects

You can initialize WordPress DinD environments in different directories:

```bash
# Project 1
mkdir ~/projects/client-a
cd ~/projects/client-a
wp-dind init
wp-dind start

# Project 2
mkdir ~/projects/client-b
cd ~/projects/client-b
wp-dind init
wp-dind start
```

### Remote Management

Manage environments from any directory:

```bash
wp-dind start -d ~/projects/client-a
wp-dind status -d ~/projects/client-b
```

### Development Workflow

```bash
# Initialize environment
wp-dind init --with-phpmyadmin --with-mailcatcher

# Start environment
wp-dind start

# Create development instance
wp-dind exec instance-manager.sh create dev 80

# Start the instance
wp-dind exec instance-manager.sh start dev

# Get access URL
wp-dind exec instance-manager.sh info dev

# View logs
wp-dind logs -f

# When done
wp-dind stop
```

## Configuration

The CLI tool stores configuration in `~/.wp-dind-config.json`:

```json
{
  "defaultImagePath": null,
  "instances": {
    "/path/to/project": {
      "created": "2025-11-03T10:00:00.000Z",
      "services": {
        "phpmyadmin": true,
        "mailcatcher": true
      }
    }
  }
}
```

## Requirements

- Node.js >= 18.0.0
- Docker
- docker-compose

## Troubleshooting

### Command not found

If `wp-dind` command is not found after installation:

1. Check if npm global bin directory is in your PATH:
   ```bash
   npm config get prefix
   ```

2. Add to your PATH (add to ~/.bashrc or ~/.zshrc):
   ```bash
   export PATH="$(npm config get prefix)/bin:$PATH"
   ```

### Docker daemon not running

Ensure Docker is running:
```bash
docker info
```

### Permission denied

On Linux, you may need to add your user to the docker group:
```bash
sudo usermod -aG docker $USER
```

Then log out and back in.

## License

MIT

