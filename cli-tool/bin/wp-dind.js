#!/usr/bin/env node

const { Command } = require('commander');
const chalk = require('chalk');
const path = require('path');
const fs = require('fs');
const { execSync, spawn } = require('child_process');
const inquirer = require('inquirer');
const ora = require('ora');
const YAML = require('yaml');

const program = new Command();

// Version
const packageJson = require('../package.json');

// Configuration
const CONFIG_FILE = path.join(process.env.HOME || process.env.USERPROFILE, '.wp-dind-config.json');

// Helper functions
function loadConfig() {
    if (fs.existsSync(CONFIG_FILE)) {
        return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    }
    return {
        defaultImagePath: null,
        instances: {}
    };
}

function saveConfig(config) {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

function execCommand(command, options = {}) {
    try {
        return execSync(command, {
            stdio: options.silent ? 'pipe' : 'inherit',
            cwd: options.cwd || process.cwd(),
            ...options
        });
    } catch (error) {
        if (!options.ignoreError) {
            console.error(chalk.red(`Error executing command: ${command}`));
            process.exit(1);
        }
        return null;
    }
}

function checkDocker() {
    try {
        execSync('docker --version', { stdio: 'pipe' });
        return true;
    } catch (error) {
        console.error(chalk.red('Docker is not installed or not running.'));
        console.error(chalk.yellow('Please install Docker from https://www.docker.com/'));
        return false;
    }
}

function checkDockerCompose() {
    try {
        execSync('docker-compose --version', { stdio: 'pipe' });
        return true;
    } catch (error) {
        console.error(chalk.red('docker-compose is not installed.'));
        console.error(chalk.yellow('Please install docker-compose'));
        return false;
    }
}

function generateDockerCompose(targetDir, config = {}) {
    const composeConfig = {
        version: '3.8',
        services: {
            'wordpress-dind': {
                image: config.dindImage || 'wp-dind:latest',
                container_name: `wp-dind-${path.basename(targetDir)}`,
                privileged: true,
                environment: {
                    ENABLE_NETWORK_ISOLATION: 'true',
                    DOCKER_TLS_CERTDIR: ''
                },
                ports: [
                    '2375:2375',
                    '8000-8099:8000-8099'
                ],
                volumes: [
                    './wordpress-instances:/wordpress-instances',
                    './shared-images:/shared-images',
                    'dind-docker-data:/var/lib/docker'
                ],
                networks: ['wordpress-dind-network'],
                restart: 'unless-stopped',
                healthcheck: {
                    test: ['CMD', 'docker', 'info'],
                    interval: '30s',
                    timeout: '10s',
                    retries: 3,
                    start_period: '40s'
                }
            }
        },
        networks: {
            'wordpress-dind-network': {
                driver: 'bridge',
                ipam: {
                    config: [{ subnet: '172.19.0.0/16' }]
                }
            }
        },
        volumes: {
            'dind-docker-data': {
                driver: 'local'
            }
        }
    };

    if (config.includePhpMyAdmin) {
        composeConfig.services.phpmyadmin = {
            image: 'wp-phpmyadmin:latest',
            container_name: `wp-phpmyadmin-${path.basename(targetDir)}`,
            environment: {
                PMA_ARBITRARY: 1,
                PMA_HOST: '',
                PMA_PORT: 3306,
                UPLOAD_LIMIT: '300M'
            },
            ports: ['8080:80'],
            volumes: ['phpmyadmin-sessions:/sessions'],
            networks: ['wordpress-dind-network'],
            restart: 'unless-stopped'
        };
        composeConfig.volumes['phpmyadmin-sessions'] = { driver: 'local' };
    }

    if (config.includeMailCatcher) {
        composeConfig.services.mailcatcher = {
            image: 'wp-mailcatcher:latest',
            container_name: `wp-mailcatcher-${path.basename(targetDir)}`,
            ports: ['1080:1080', '1025:1025'],
            networks: ['wordpress-dind-network'],
            restart: 'unless-stopped'
        };
    }

    return YAML.stringify(composeConfig);
}

// Commands

program
    .name('wp-dind')
    .description('WordPress Docker-in-Docker CLI Manager')
    .version(packageJson.version);

program
    .command('init')
    .description('Initialize WordPress DinD environment in current directory')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .option('--with-phpmyadmin', 'Include phpMyAdmin service')
    .option('--with-mailcatcher', 'Include MailCatcher service')
    .action(async (options) => {
        if (!checkDocker() || !checkDockerCompose()) {
            process.exit(1);
        }

        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();
        
        console.log(chalk.blue.bold('\n🚀 WordPress Docker-in-Docker Initializer\n'));
        console.log(chalk.gray(`Target directory: ${targetDir}\n`));

        // Check if directory exists
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }

        // Check if already initialized
        const composeFile = path.join(targetDir, 'docker-compose.yml');
        if (fs.existsSync(composeFile)) {
            const answers = await inquirer.prompt([{
                type: 'confirm',
                name: 'overwrite',
                message: 'docker-compose.yml already exists. Overwrite?',
                default: false
            }]);

            if (!answers.overwrite) {
                console.log(chalk.yellow('Initialization cancelled.'));
                process.exit(0);
            }
        }

        // Interactive configuration
        const answers = await inquirer.prompt([
            {
                type: 'confirm',
                name: 'includePhpMyAdmin',
                message: 'Include phpMyAdmin for database management?',
                default: options.withPhpmyadmin || true
            },
            {
                type: 'confirm',
                name: 'includeMailCatcher',
                message: 'Include MailCatcher for email testing?',
                default: options.withMailcatcher || true
            }
        ]);

        const spinner = ora('Generating configuration files...').start();

        // Create necessary directories
        const dirs = ['wordpress-instances', 'shared-images', 'logs'];
        dirs.forEach(dir => {
            const dirPath = path.join(targetDir, dir);
            if (!fs.existsSync(dirPath)) {
                fs.mkdirSync(dirPath, { recursive: true });
            }
        });

        // Generate docker-compose.yml
        const composeContent = generateDockerCompose(targetDir, answers);
        fs.writeFileSync(composeFile, composeContent);

        // Create .env file
        const envContent = `# WordPress Docker-in-Docker Environment
# Generated by wp-dind CLI

# Docker-in-Docker Configuration
ENABLE_NETWORK_ISOLATION=true
DOCKER_TLS_CERTDIR=

# Port Configuration
DIND_PORT=2375
PHPMYADMIN_PORT=8080
MAILCATCHER_WEB_PORT=1080
MAILCATCHER_SMTP_PORT=1025
`;
        fs.writeFileSync(path.join(targetDir, '.env'), envContent);

        // Create README
        const readmeContent = `# WordPress Docker-in-Docker Environment

This directory contains a WordPress Docker-in-Docker (DinD) environment.

## Quick Start

1. Start the environment:
   \`\`\`bash
   wp-dind start
   \`\`\`

2. Create a WordPress instance:
   \`\`\`bash
   wp-dind exec dind instance-manager.sh create mysite 80 83 nginx
   \`\`\`

3. Access your WordPress site:
   - WordPress: http://localhost:8000 (or next available port)
   - phpMyAdmin: http://localhost:8080
   - MailCatcher: http://localhost:1080

## Available Commands

### Environment Management
- \`wp-dind start\` - Start the DinD environment
- \`wp-dind stop\` - Stop the DinD environment
- \`wp-dind status\` - Check environment status
- \`wp-dind ps\` - List all containers
- \`wp-dind logs [-f] [-s service]\` - View logs
- \`wp-dind destroy\` - Destroy environment (removes all data)

### Execute Commands
- \`wp-dind exec dind <command>\` - Execute command in DinD host
- \`wp-dind exec <container> <command>\` - Execute command in specific container

### Examples

**Create WordPress instance:**
\`\`\`bash
wp-dind exec dind instance-manager.sh create mysite 80 83 nginx
# Arguments: name mysql_version php_version webserver
# mysql_version: 56, 57, 80
# php_version: 74, 80, 81, 82, 83
# webserver: nginx, apache
\`\`\`

**List WordPress instances:**
\`\`\`bash
wp-dind exec dind instance-manager.sh list
\`\`\`

**Execute WP-CLI in a WordPress instance:**
\`\`\`bash
wp-dind exec mysite-php wp --info
wp-dind exec mysite-php wp plugin list
wp-dind exec mysite-php wp user list
\`\`\`

**Access MySQL in an instance:**
\`\`\`bash
wp-dind exec mysite-mysql mysql -u wordpress -p
\`\`\`

**View instance logs:**
\`\`\`bash
wp-dind exec dind instance-manager.sh logs mysite
wp-dind exec dind instance-manager.sh logs mysite php
\`\`\`

**Access container shell:**
\`\`\`bash
wp-dind exec -i mysite-php bash
wp-dind exec -i mysite-mysql bash
\`\`\`

## Services

${answers.includePhpMyAdmin ? '- **phpMyAdmin**: http://localhost:8080\n' : ''}${answers.includeMailCatcher ? '- **MailCatcher**: http://localhost:1080\n' : ''}
## Directory Structure

- \`wordpress-instances/\` - WordPress instance data
- \`shared-images/\` - Shared Docker images
- \`logs/\` - Application logs
`;
        fs.writeFileSync(path.join(targetDir, 'README.md'), readmeContent);

        spinner.succeed('Configuration files generated successfully!');

        console.log(chalk.green('\n✅ WordPress DinD environment initialized!\n'));
        console.log(chalk.yellow('Next steps:'));
        console.log(chalk.gray('  1. cd ' + targetDir));
        console.log(chalk.gray('  2. wp-dind start'));
        console.log(chalk.gray('  3. wp-dind exec dind instance-manager.sh create mysite 80 83 nginx'));
        console.log(chalk.gray('  4. wp-dind ps (to see all containers)'));
        console.log(chalk.gray('  5. wp-dind exec mysite-php wp --info\n'));

        // Save to config
        const config = loadConfig();
        config.instances[targetDir] = {
            created: new Date().toISOString(),
            services: {
                phpmyadmin: answers.includePhpMyAdmin,
                mailcatcher: answers.includeMailCatcher
            }
        };
        saveConfig(config);
    });

program
    .command('start')
    .description('Start the WordPress DinD environment')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .action((options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();
        const composeFile = path.join(targetDir, 'docker-compose.yml');

        if (!fs.existsSync(composeFile)) {
            console.error(chalk.red('No docker-compose.yml found. Run "wp-dind init" first.'));
            process.exit(1);
        }

        console.log(chalk.blue('Starting WordPress DinD environment...\n'));
        execCommand('docker-compose up -d', { cwd: targetDir });
        console.log(chalk.green('\n✅ Environment started successfully!\n'));
        console.log(chalk.yellow('Run "wp-dind status" to check the status.'));
    });

program
    .command('stop')
    .description('Stop the WordPress DinD environment')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .action((options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();
        console.log(chalk.blue('Stopping WordPress DinD environment...\n'));
        execCommand('docker-compose stop', { cwd: targetDir });
        console.log(chalk.green('\n✅ Environment stopped successfully!'));
    });

program
    .command('status')
    .description('Check the status of the WordPress DinD environment')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .action((options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();
        console.log(chalk.blue('WordPress DinD Environment Status:\n'));
        execCommand('docker-compose ps', { cwd: targetDir });
    });

program
    .command('logs')
    .description('View logs from the WordPress DinD environment')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .option('-f, --follow', 'Follow log output')
    .option('-s, --service <service>', 'Show logs for specific service')
    .action((options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();
        let cmd = 'docker-compose logs';
        if (options.follow) cmd += ' -f';
        if (options.service) cmd += ` ${options.service}`;
        
        execCommand(cmd, { cwd: targetDir });
    });

program
    .command('exec <container> <command...>')
    .description('Execute a command inside a specific Docker container')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .option('-i, --interactive', 'Run in interactive mode (allocate TTY)', false)
    .option('-u, --user <user>', 'Run as specific user (e.g., www-data, root)')
    .action((container, command, options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();

        // Check if we're targeting the DinD host or a WordPress instance container
        let dockerCmd;

        if (container === 'dind' || container === 'host') {
            // Execute in the DinD host container
            dockerCmd = `docker-compose exec`;
            if (options.user) dockerCmd += ` -u ${options.user}`;
            if (!options.interactive) dockerCmd += ` -T`;
            dockerCmd += ` wordpress-dind ${command.join(' ')}`;
        } else {
            // Execute in a WordPress instance container (inside DinD)
            // Format: <instance-name>-<service> or just <container-name>
            dockerCmd = `docker-compose exec`;
            if (!options.interactive) dockerCmd += ` -T`;
            dockerCmd += ` wordpress-dind docker exec`;
            if (options.interactive) dockerCmd += ` -it`;
            if (options.user) dockerCmd += ` -u ${options.user}`;
            dockerCmd += ` ${container} ${command.join(' ')}`;
        }

        console.log(chalk.gray(`Executing: ${dockerCmd}\n`));
        execCommand(dockerCmd, { cwd: targetDir });
    });

program
    .command('instance <action> [args...]')
    .description('Manage WordPress instances (create, start, stop, remove, list, info, logs)')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .action((action, args, options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();

        const validActions = ['create', 'start', 'stop', 'remove', 'list', 'info', 'logs'];
        if (!validActions.includes(action)) {
            console.error(chalk.red(`Invalid action: ${action}`));
            console.log(chalk.yellow(`Valid actions: ${validActions.join(', ')}`));
            process.exit(1);
        }

        const cmd = `docker-compose exec -T wordpress-dind instance-manager.sh ${action} ${args.join(' ')}`;
        execCommand(cmd, { cwd: targetDir });
    });

program
    .command('ps')
    .description('List all containers (DinD host and WordPress instances)')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .option('-a, --all', 'Show all containers (including stopped)')
    .action((options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();

        console.log(chalk.blue.bold('WordPress DinD Containers:\n'));

        // Show DinD host container
        console.log(chalk.yellow('DinD Host Container:'));
        execCommand('docker-compose ps', { cwd: targetDir });

        // Show WordPress instance containers (inside DinD)
        console.log(chalk.yellow('\nWordPress Instance Containers (inside DinD):'));
        const psCmd = options.all ? 'docker ps -a' : 'docker ps';
        execCommand(`docker-compose exec -T wordpress-dind ${psCmd}`, {
            cwd: targetDir,
            ignoreError: true
        });
    });

program
    .command('destroy')
    .description('Destroy the WordPress DinD environment (removes all data)')
    .option('-d, --dir <directory>', 'Target directory (default: current directory)')
    .action(async (options) => {
        const targetDir = options.dir ? path.resolve(options.dir) : process.cwd();

        const answers = await inquirer.prompt([{
            type: 'confirm',
            name: 'confirm',
            message: chalk.red('This will remove all containers, volumes, and data. Are you sure?'),
            default: false
        }]);

        if (!answers.confirm) {
            console.log(chalk.yellow('Cancelled.'));
            process.exit(0);
        }

        console.log(chalk.blue('Destroying WordPress DinD environment...\n'));
        execCommand('docker-compose down -v', { cwd: targetDir });
        console.log(chalk.green('\n✅ Environment destroyed successfully!'));
    });

program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
    program.outputHelp();
}

