#include <GLUT/glut.h>  // Use this for macOS, which uses the GLUT framework
#ifndef GL_SILENCE_DEPRECATION
#define GL_SILENCE_DEPRECATION
#endif

#include "stb_image.h"
#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>
#import <AVFoundation/AVFoundation.h>
#include <dispatch/dispatch.h>
#import <Cocoa/Cocoa.h>

// Global Variables
bool isGameOver = false;
bool isMusicPlaying = true;
bool gameOverAudioInitialized = false;
bool isStartScreen = true;
bool isPaused = true;
bool isInvisible = false;
float invisibilityDuration = 3.0f;
unsigned long invisibilityStartTime = 0;
bool isBlinking = false;
unsigned long lastBlinkTime = 0;
unsigned long blinkInterval = 250; // 250 milliseconds
float playerX = 0.0f;
float playerY = 0.0f;
GLuint playerTexture;
GLuint shipTexture;
GLuint startScreenTexture;
unsigned long lastInputTime = 0;
unsigned long inputDebounceInterval = 100; // 100 milliseconds
AVAudioEngine* gameplayAudioEngine;
AVAudioPlayerNode* gameplayAudioPlayerNode;
AVAudioFile* gameplayAudioFile;
AVAudioEngine* gameOverAudioEngine;
AVAudioPlayerNode* gameOverAudioPlayerNode;
AVAudioFile* gameOverAudioFile;
GLuint treeTexture2, treeTexture3, treeTexture4, treeTexture6, treeTexture7, treeTexture9;
GLuint CoinTexture;
GLuint carTexture;
GLuint powerUpTexture;
int score = 0;

// Struct Definitions
struct Car {
    float x;
    float y;
    float width;
    float height;
    float speed;
};

// coin structure
struct Coin {
    float x;
    float y;
    float width;
    float height;
    float speed;
    bool isActive;
};

// powerup structure
struct PowerUp {
    float x;
    float y;
    float width;
    float height;
    float speed;
    bool isActive;
};

// Vector of Car objects representing the cars in the game
std::vector<Car> cars = {
        {0.1f, -0.8f, 0.12f, 0.15f, -0.0075f},
        {0.2f, 0.8f, 0.12f, 0.15f, -0.0045f},
        {-0.1f, 0.8f, 0.12f, 0.15f, -0.0025f}
};

// Vector of Coin objects representing the coins in the game
std::vector<Coin> coins = {
        {0.1f, 1.0f, 0.2f, 0.2f, -0.008f, true},
        {0.0f, 0.8f, 0.2f, 0.2f, -0.003f, true},
        {-0.1f, 0.8f, 0.2f, 0.2f, -0.004f, true},
};

std::vector<PowerUp> powerUps;

extern "C" void minimizeCurrentWindow();  // Ensure this is declared with extern "C"

// Load texture from file
GLuint loadTexture(const char* filename) {
    int width, height, channels;
    stbi_set_flip_vertically_on_load(true);
    unsigned char* image = stbi_load(filename, &width, &height, &channels, STBI_rgb_alpha);
    if (image == nullptr) {
        std::cerr << "Error loading texture " << filename << std::endl;
        exit(1);
    }

    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image);

    stbi_image_free(image);
    return textureID;
}

// Initialize coin textures
void initCoinTexture() {
    carTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/car.png");
    CoinTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/coin.png");
}

// Initialize power-up textures
void initPowerUpTexture() {
    powerUpTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/png.png"); // Update the path to your image file
}

// Initialize gameplay audio
void initGameplayAudio() {
    gameplayAudioEngine = [[AVAudioEngine alloc] init];
    gameplayAudioPlayerNode = [[AVAudioPlayerNode alloc] init];
    [gameplayAudioEngine attachNode:gameplayAudioPlayerNode];

    NSError* error = nil;
    NSURL* gameplayFileURL = [NSURL fileURLWithPath:@"/Users/chetanvarma/Desktop/GameTesting 6/Sakura-Girl-Motivation-chosic.com_.mp3"];
    gameplayAudioFile = [[AVAudioFile alloc] initForReading:gameplayFileURL error:&error];
    if (error) {
        NSLog(@"Error loading gameplay audio file: %@", error);
        return;
    }

    [gameplayAudioEngine connect:gameplayAudioPlayerNode to:[gameplayAudioEngine mainMixerNode] format:[gameplayAudioFile processingFormat]];
    [gameplayAudioPlayerNode scheduleFile:gameplayAudioFile atTime:nil completionHandler:nil];

    [gameplayAudioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"Error starting gameplay audio engine: %@", error);
    }

    [gameplayAudioPlayerNode play];
}

// Initialize game over audio
void initGameOverAudio() {
    gameOverAudioEngine = [[AVAudioEngine alloc] init];
    gameOverAudioPlayerNode = [[AVAudioPlayerNode alloc] init];
    [gameOverAudioEngine attachNode:gameOverAudioPlayerNode];

    NSError* error = nil;
    NSURL* gameOverFileURL = [NSURL fileURLWithPath:@"/Users/chetanvarma/Desktop/GameTesting 6/distant-ambulance-siren-6108.mp3"];
    gameOverAudioFile = [[AVAudioFile alloc] initForReading:gameOverFileURL error:&error];
    if (error) {
        NSLog(@"Error loading game over audio file: %@", error);
        return;
    }

    [gameOverAudioEngine connect:gameOverAudioPlayerNode to:[gameOverAudioEngine mainMixerNode] format:[gameOverAudioFile processingFormat]];
    [gameOverAudioPlayerNode scheduleFile:gameOverAudioFile atTime:nil completionHandler:nil];

    [gameOverAudioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"Error starting game over audio engine: %@", error);
    }
}

// Play game over music
void playGameOverMusic() {
    [gameOverAudioPlayerNode play];
}

// Stop gameplay audio
void stopGameplayAudio() {
    if ([gameplayAudioEngine isRunning]) {
        [gameplayAudioPlayerNode stop];
        [gameplayAudioEngine stop];
    } else {
        NSLog(@"Attempted to stop gameplay audio but the engine was not running.");
    }
}

// Cleanup game over audio
void cleanupGameOverAudio() {
    if ([gameOverAudioEngine isRunning]) {
        [gameOverAudioPlayerNode stop];
        [gameOverAudioEngine stop];
        NSLog(@"Game over audio stopped successfully.");
    } else {
        NSLog(@"Game over audio was not running at the time of cleanup.");
    }
}

// Transition to gameplay audio
void transitionToGameplay() {
    if ([gameOverAudioEngine isRunning]) {
        [gameOverAudioPlayerNode stop];
        [gameOverAudioEngine stop];
    }

    if (![gameplayAudioEngine isRunning]) {
        initGameplayAudio();
    } else {
        NSLog(@"Gameplay audio engine was already running.");
    }
}

// Transition to game over audio
void transitionToGameOver() {
    if ([gameplayAudioEngine isRunning]) {
        [gameplayAudioPlayerNode stop];
        [gameplayAudioEngine stop];
        NSLog(@"Gameplay audio stopped successfully.");
    } else {
        NSLog(@"Gameplay audio was not running at the time of transition to game over.");
    }

    if (![gameOverAudioEngine isRunning]) {
        initGameOverAudio();
        NSLog(@"Game over audio initialized.");
    } else {
        NSLog(@"Game over audio was already initialized and running.");
    }
}

// Ensure gameplay audio stopped
void ensureGameplayAudioStopped() {
    if ([gameplayAudioEngine isRunning]) {
        [gameplayAudioPlayerNode stop];
        [gameplayAudioEngine stop];
        NSLog(@"Gameplay audio stopped successfully.");
    } else {
        NSLog(@"Attempted to stop gameplay audio but the engine was not running.");
    }
}

// Ensure gameplay audio started
void ensureGameplayAudioStarted() {
    if (![gameplayAudioEngine isRunning]) {
        initGameplayAudio();
        NSLog(@"Gameplay audio started successfully.");
    } else {
        NSLog(@"Attempted to start gameplay audio but the engine was already running.");
    }
}

// Manage audio state
void manageAudioState(bool isGameOver) {
    if (isGameOver) {
        ensureGameplayAudioStopped();
        if (!gameOverAudioInitialized) {
            initGameOverAudio();
            gameOverAudioInitialized = true;
        }
        playGameOverMusic();
    } else {
        ensureGameplayAudioStarted();
    }
}

// Set up the projection matrix
void GameOverImage1() {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);

    // Set up the modelview matrix
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // Enable blending for transparency
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    GLuint gameOverTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/pixel-art-ambulance-death-spirit_150088-627.png");
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, gameOverTexture);
    glColor3f(1.0f, 1.0f, 1.0f);

    // Draw the textured quad
    float quadSize = 0.8f;
    float halfQuadSize = quadSize / 1.0f;
    glBegin(GL_QUADS);
    glTexCoord2f(0.0f, 0.0f); glVertex2f(-halfQuadSize, -halfQuadSize);
    glTexCoord2f(1.0f, 0.0f); glVertex2f(halfQuadSize, -halfQuadSize);
    glTexCoord2f(1.0f, 1.0f); glVertex2f(halfQuadSize, halfQuadSize);
    glTexCoord2f(0.0f, 1.0f); glVertex2f(-halfQuadSize, halfQuadSize);
    glEnd();
}

// Load the second texture
void GameOverImage2() {
    GLuint secondTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/game over.png");
    glBindTexture(GL_TEXTURE_2D, secondTexture);

    float quadSize = 0.8f;
    float halfQuadSize = quadSize / 1.0f;
    float newSizeFactor = 0.6f;
    float newHalfQuadSize = 0.6f * newSizeFactor;
    glBegin(GL_QUADS);
    glTexCoord2f(0.0f, 0.0f); glVertex2f(-newHalfQuadSize, -halfQuadSize + 1.5 - newHalfQuadSize);
    glTexCoord2f(1.0f, 0.0f); glVertex2f(newHalfQuadSize + 0.3, -halfQuadSize + 1.5 - newHalfQuadSize);
    glTexCoord2f(1.0f, 1.0f); glVertex2f(newHalfQuadSize + 0.3, -halfQuadSize + 1.5 + newHalfQuadSize);
    glTexCoord2f(0.0f, 1.0f); glVertex2f(-newHalfQuadSize, -halfQuadSize + 1.5 + newHalfQuadSize);
    glEnd();
}

// Display game over screen
void displayGameOverScreen() {
    if (!gameOverAudioInitialized) {
        transitionToGameOver();
        gameOverAudioInitialized = true;
    }
    playGameOverMusic();
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    std::cout << "Displaying Game Over Screen" << std::endl;

    GameOverImage1();

    GameOverImage2();

    glDisable(GL_TEXTURE_2D);

    glColor3f(1.0, 0.0, 0.0);
    float buttonWidth = 0.2f;
    float buttonHeight = 0.1f;
    float buttonX = -buttonWidth / 2;
    float buttonY = -0.3f;
    glBegin(GL_QUADS);
    glVertex2f(buttonX, buttonY);
    glVertex2f(buttonX + buttonWidth, buttonY);
    glVertex2f(buttonX + buttonWidth, buttonY + buttonHeight);
    glVertex2f(buttonX, buttonY + buttonHeight);
    glEnd();

    glColor3f(1.0f, 1.0f, 1.0f);
    glRasterPos2f(buttonX + 0.05f, buttonY + 0.05f);
    std::string buttonText = "Restart";
    for (char& c : buttonText) {
        glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
    }
    glFlush();
}

// Check collision with cars
bool checkCollision(const Car& car) {
    if (isInvisible) {
        return false; // Ignore collisions if the player is invisible
    }
    float playerPadding = 0.05f;
    float playerLeft = playerX - 0.1f + playerPadding;
    float playerRight = playerX + 0.1f - playerPadding;
    float playerTop = playerY + 0.1f - playerPadding;
    float playerBottom = playerY - 0.1f + playerPadding;

    float carPadding = 0.02f;
    float carLeft = car.x + carPadding;
    float carRight = car.x + car.width - carPadding;
    float carTop = car.y + car.height - carPadding;
    float carBottom = car.y + carPadding;

    bool noOverlap = carLeft > playerRight || carRight < playerLeft ||
                     carTop < playerBottom || carBottom > playerTop;

    return !noOverlap;
}

// Check collision with coins
bool checkCollisionCoin(const Coin& coin) {
    float playerLeft = playerX;
    float playerRight = playerX;
    float playerTop = playerY;
    float playerBottom = playerY;

    float coinLeft = coin.x;
    float coinRight = coin.x + coin.width;
    float coinTop = coin.y + coin.height;
    float coinBottom = coin.y;

    bool overlap = !(coinLeft > playerRight || coinRight < playerLeft ||
                     coinTop < playerBottom || coinBottom > playerTop);

    return overlap;
}

// Check collision with power-up
bool checkCollisionPowerUp(const PowerUp& powerUp) {
    float playerLeft = playerX;
    float playerRight = playerX;
    float playerTop = playerY;
    float playerBottom = playerY;

    float powerUpLeft = powerUp.x;
    float powerUpRight = powerUp.x + powerUp.width;
    float powerUpTop = powerUp.y + powerUp.height;
    float powerUpBottom = powerUp.y;

    bool overlap = !(powerUpLeft > playerRight || powerUpRight < playerLeft ||
                     powerUpTop < playerBottom || powerUpBottom > playerTop);

    return overlap;
}

// Adjust car speeds based on score
void adjustCarSpeeds() {
    std::vector<float> speedAdjustments = { -0.0015f, -0.0019f, -0.023f };
    std::vector<float> speedCaps = { -0.010f, -0.015f, -0.020f };

    int index = 0;
    for (auto& car : cars) {
        if (score > 150) {
            car.speed = std::max(car.speed + (speedAdjustments[index] * 2.5f), speedCaps[index] * 3.0f);
        }
        else if (score > 100) {
            car.speed = std::max(car.speed + (speedAdjustments[index] * 1.5f), speedCaps[index] * 2.0f);
        }
        else if (score > 50) {
            car.speed = std::max(car.speed + speedAdjustments[index], speedCaps[index]);
        }
        index++;
    }
}

// Update car positions
void updateCarPositions(int value) {
    if (isGameOver) {
        return;
    }
    if (!isPaused && !isGameOver) {
        adjustCarSpeeds();
        for (auto& car : cars) {
            car.y += car.speed;
            if (car.y > 1.0f) {
                car.y = -1.0f;
            }
            else if (car.y < -1.0f) {
                car.y = 1.0f;
            }
            if (checkCollision(car)) {
                isGameOver = true;
                displayGameOverScreen();
                glutPostRedisplay();
                return;
            }
        }
        glutPostRedisplay();
    }

    if (!isGameOver) {
        glutTimerFunc(16, updateCarPositions, 0);
    }
}

// Update coin positions
void updateCoins(int value) {
    if (!isPaused && !isGameOver) {
        for (auto& coin : coins) {
            coin.y += coin.speed;
            if (coin.y < -1.0f) {
                coin.y = 1.0f;
                float roadLeft = -0.1f;
                float roadRight = 0.2f;
                float roadWidth = roadRight - roadLeft;
                coin.x = roadLeft + static_cast<float>(rand()) / static_cast<float>(RAND_MAX) * roadWidth;
                coin.isActive = true;
            }
            if (coin.isActive && checkCollisionCoin(coin)) {
                std::cout << "Coin collected! +10 points" << std::endl;
                score += 10;
                coin.isActive = false;
                if (score %50 == 0) { // Spawn a power-up every 50 points
                    PowerUp newPowerUp = {0.0f, 1.0f, 0.1f, 0.1f, -0.005f, true};
                    powerUps.push_back(newPowerUp);
                }
            }
        }
        glutPostRedisplay();
    }
    if (!isGameOver) {
        glutTimerFunc(16, updateCoins, 0);
    }
}

// Update power-up positions
void updatePowerUps(int value) {
    if (!isPaused && !isGameOver) {
        for (auto& powerUp : powerUps) {
            powerUp.y += powerUp.speed;
            if (powerUp.y < -1.0f) {
                powerUp.y = 1.0f;
                float roadLeft = -0.1f;
                float roadRight = 0.2f;
                float roadWidth = roadRight - roadLeft;
                powerUp.x = roadLeft + static_cast<float>(rand()) / static_cast<float>(RAND_MAX) * roadWidth;
                powerUp.isActive = true;
            }
            if (powerUp.isActive && checkCollisionPowerUp(powerUp)) {
                std::cout << "Power-up collected! Invisibility for 5 seconds" << std::endl;
                isInvisible = true;
                invisibilityStartTime = glutGet(GLUT_ELAPSED_TIME);
                powerUp.isActive = false;
            }
        }
        glutPostRedisplay();
    }
    if (!isGameOver) {
        glutTimerFunc(16, updatePowerUps, 0);
    }
}

// Handle invisibility duration
void updateInvisibility() {
    if (isInvisible) {
        unsigned long currentTime = glutGet(GLUT_ELAPSED_TIME);
        if (currentTime - invisibilityStartTime >= invisibilityDuration * 1000) {
            isInvisible = false;
            std::cout << "Invisibility ended" << std::endl;
        }
        if (currentTime - lastBlinkTime >= blinkInterval) {
            isBlinking = !isBlinking;
            lastBlinkTime = currentTime;
        }
    }
}

// Render bitmap string
void renderBitmapString(float x, float y, void* font, const char* string) {
    const char* c;
    glRasterPos2f(x, y);
    for (c = string; *c != '\0'; c++) {
        glutBitmapCharacter(font, *c);
    }
}

// Reset game objects
void resetGameObjects() {
    playerX = 0.0f;
    playerY = 0.0f;
    cars = {
            {0.1f, -0.8f, 0.12f, 0.15f, -0.0075f},
            {0.2f, 0.8f, 0.12f, 0.15f, -0.0045f},
            {-0.1f, 0.8f, 0.12f, 0.15f, -0.0025f}
    };
    coins = {
            {0.1f, 1.0f, 0.2f, 0.2f, -0.008f, true},
            {0.0f, 0.8f, 0.2f, 0.2f, -0.003f, true},
            {-0.1f, 0.8f, 0.2f, 0.2f, -0.004f, true},
    };
    powerUps.clear();
    score = 0;
    isPaused = false;
    isGameOver = false;
    gameOverAudioInitialized = false;
    isInvisible = false;
    isBlinking = false;
    manageAudioState(false);
}

// Restart game
void restartGame() {
    std::cout << "Restarting game..." << std::endl;
    stopGameplayAudio();
    cleanupGameOverAudio();
    resetGameObjects();
    transitionToGameplay();
    glutTimerFunc(16, updateCarPositions, 0);
    glutTimerFunc(16, updateCoins, 0);
    glutTimerFunc(16, updatePowerUps, 0);
    glutPostRedisplay();
}

// Start game from the start screen
void startGame() {
    isStartScreen = false;
    isPaused = false; // Unpause the game when starting
    resetGameObjects();
    transitionToGameplay();
    glutTimerFunc(16, updateCarPositions, 0);
    glutTimerFunc(16, updateCoins, 0);
    glutTimerFunc(16, updatePowerUps, 0);
    glutPostRedisplay();
}

// Handle mouse move events
void handleMouseMove(int x, int y) {
    float openglX = (x / (float)glutGet(GLUT_WINDOW_WIDTH)) * 2.0f - 1.0f;
    float openglY = 1.0f - (y / (float)glutGet(GLUT_WINDOW_HEIGHT)) * 2.0f;

    float lightSize = 0.05f;
    float lightX = 0.5f;
    float redLightY = 0.3f;
    float yellowLightY = 0.15f;
    float greenLightY = 0.0f;

    bool overAnyLight = false;
    for (float lightY : {redLightY, yellowLightY, greenLightY}) {
        float minX = lightX - lightSize;
        float maxX = lightX + lightSize;
        float minY = lightY - lightSize;
        float maxY = lightY + lightSize;

        if (openglX >= minX && openglX <= maxX && openglY >= minY && openglY <= maxY) {
            glutSetCursor(GLUT_CURSOR_INFO);
            overAnyLight = true;
            break;
        }
    }

    float buttonWidth = 0.2f;
    float buttonHeight = 0.1f;
    float buttonX = -buttonWidth / 2;
    float buttonY = -0.3f;

    // Start button dimensions
    float buttonWidth1 = 0.3f;
    float buttonHeight1 = 0.2f;
    float buttonX1 = -buttonWidth1 / 2;
    float buttonY1 = -0.9f;

    if (isGameOver) {
        bool isRestartButtonHovered = (openglX >= buttonX && openglX <= (buttonX + buttonWidth) &&
                                       openglY >= buttonY && openglY <= (buttonY + buttonHeight));
        if (isRestartButtonHovered) {
            glutSetCursor(GLUT_CURSOR_INFO);
        }
        else if (!overAnyLight) {
            glutSetCursor(GLUT_CURSOR_LEFT_ARROW);
        }
    }
    else if (isStartScreen) {
        bool isStartButtonHovered = (openglX >= buttonX1 && openglX <= (buttonX1 + buttonWidth1) &&
                                     openglY >= buttonY1 && openglY <= (buttonY1 + buttonHeight1));
        if (isStartButtonHovered) {
            glutSetCursor(GLUT_CURSOR_INFO);
        }
        else if (!overAnyLight) {
            glutSetCursor(GLUT_CURSOR_LEFT_ARROW);
        }
    }
    else {
        if (!overAnyLight) {
            glutSetCursor(GLUT_CURSOR_LEFT_ARROW);
        }
    }
}

// Draw arrow
void drawArrow(float x, float y, float size) {
    glBegin(GL_TRIANGLES);
    glVertex2f(x, y);
    glVertex2f(x + size, y + size);
    glVertex2f(x + size, y - size);
    glEnd();
}

// Draw text
void drawText(const char* text, float x, float y) {
    glRasterPos2f(x, y);
    while (*text) {
        glutBitmapCharacter(GLUT_BITMAP_8_BY_13, *text);
        text++;
    }
}

// Draw textured ship
void drawTexturedShip(float shipBase, float shipWidth, float shipHeight) {
    if (!shipTexture) {
        shipTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/92e3e119a5399dc0f0810405026b008a.png");
    }

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, shipTexture);
    glColor3f(1.0f, 1.0f, 1.0f);

    glPushMatrix();
    glTranslatef(shipBase, -0.1f, 0.0f);

    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex2f(0, 0);
    glTexCoord2f(1.0, 0.0); glVertex2f(shipWidth, 0);
    glTexCoord2f(1.0, 1.0); glVertex2f(shipWidth, shipHeight);
    glTexCoord2f(0.0, 1.0); glVertex2f(0, shipHeight);
    glEnd();

    glPopMatrix();
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
}

// Initialize tree textures
void initTreeTextures() {
    treeTexture2 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/tree2.png");
    treeTexture3 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/tree3.png");
    treeTexture4 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/tree4.png");
    treeTexture6 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/tree6.png");
    treeTexture7 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/tree7.png");
    treeTexture9 = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.png");
}

// Draw tree
void drawTree(GLuint texture, float x, float y, float width, float height) {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture);
    glColor3f(1.0f, 1.0f, 1.0f);

    glPushMatrix();
    glTranslatef(x, y, 0.0f);

    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex2f(0, 0);
    glTexCoord2f(1.0, 0.0); glVertex2f(width, 0);
    glTexCoord2f(1.0, 1.0); glVertex2f(width, height);
    glTexCoord2f(0.0, 1.0); glVertex2f(0, height);
    glEnd();

    glPopMatrix();

    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
}

// Draw tree series
void drawTrees(GLuint texture, float startX, float startY, float stepX, float stepY, int count, float width, float height) {
    for (int i = 0; i < count; ++i) {
        drawTree(texture, startX + stepX * i, startY + stepY * i, width, height);
    }
}

// Handle mouse click events
void handleMouseClick(int button, int state, int x, int y) {
    if (button == GLUT_LEFT_BUTTON && state == GLUT_DOWN) {
        float openglX = (x / (float)glutGet(GLUT_WINDOW_WIDTH)) * 2.0f - 1.0f;
        float openglY = 1.0f - (y / (float)glutGet(GLUT_WINDOW_HEIGHT)) * 2.0f;

        float buttonX = -0.1f;
        float buttonY = -0.3f;
        float buttonWidth = 0.2f;
        float buttonHeight = 0.1f;

        // Start button dimensions
        float buttonWidth1 = 1.4f;
        float buttonHeight1 = 1.2f;
        float buttonX1 = -buttonWidth1 / 2;
        float buttonY1 = -0.9f;

        if (isStartScreen) {
            if (openglX >= buttonX1 && openglX <= buttonX1 + buttonWidth1 &&
                openglY >= buttonY1 && openglY <= buttonY1 + buttonHeight1) {
                startGame();
            }
        }
        else if (isGameOver) {
            if (openglX >= buttonX && openglX <= buttonX + buttonWidth &&
                openglY >= buttonY && openglY <= buttonY + buttonHeight) {
                restartGame();
            }
        }

        // Define the properties for the red light
        float redLightX = 0.5f;
        float redLightY = 0.3f;
        float redLightSize = 0.05f;
        float redMinX = redLightX - redLightSize;
        float redMaxX = redLightX + redLightSize;
        float redMinY = redLightY - redLightSize;
        float redMaxY = redLightY + redLightSize;

        // Define the properties for the yellow light
        float yellowLightX = 0.5f;
        float yellowLightY = 0.15f;
        float yellowLightSize = 0.05f;
        float yellowMinX = yellowLightX - yellowLightSize;
        float yellowMaxX = yellowLightX + yellowLightSize;
        float yellowMinY = yellowLightY - yellowLightSize;
        float yellowMaxY = yellowLightY + yellowLightSize;

        // Check if the mouse click is within the yellow light boundaries
        if (openglX >= yellowMinX && openglX <= yellowMaxX && openglY >= yellowMinY && openglY <= yellowMaxY) {
            std::cout << "Yellow light clicked. Minimizing window." << std::endl;
            minimizeCurrentWindow();
        }
        // Check if the mouse click is within the red light boundaries
        if (openglX >= redMinX && openglX <= redMaxX && openglY >= redMinY && openglY <= redMaxY) {
            std::cout << "Red light clicked. Exiting game." << std::endl;
            exit(0);
        }


        float lightX = 0.5f;
        float greenLightY = 0.0f;
        float lightSize = 0.05f;
        float greenMinX = lightX - lightSize;
        float greenMaxX = lightX + lightSize;
        float greenMinY = greenLightY - lightSize;
        float greenMaxY = greenLightY + lightSize;

        if (openglX >= greenMinX && openglX <= greenMaxX && openglY >= greenMinY && openglY <= greenMaxY) {
            isPaused = !isPaused;
            isMusicPlaying = !isMusicPlaying;

            if (isPaused) {
                stopGameplayAudio();
                std::cout << "Game paused. Music paused." << std::endl;
            }
            else {
                initGameplayAudio();
                std::cout << "Game resumed. Music playing." << std::endl;
            }
        }
    }
}

// Draw traffic light
void drawTrafficLight(float x, float y) {
    float lightSize = 0.05;
    glColor3f(0.8, 0.8, 0.8);
    glBegin(GL_QUADS);
    glVertex2f(x - 0.01, y);
    glVertex2f(x + 0.01, y);
    glVertex2f(x + 0.01, y - 0.4);
    glVertex2f(x - 0.01, y - 0.4);
    glEnd();

    struct Light {
        float r, g, b;
        float dy;
        const char* label;
    } lights[] = {
            {1.0, 0.0, 0.0, -0.05, "Close"},
            {1.0, 1.0, 0.0, -0.15, "Minimize"},
            {0.0, 1.0, 0.0, -0.25, "Pause/Continue"}
    };

    for (const auto& light : lights) {
        glColor3f(light.r, light.g, light.b);
        glBegin(GL_POLYGON);
        for (int i = 0; i < 360; i++) {
            float degInRad = i * 3.14159 / 180;
            glVertex2f(cos(degInRad) * lightSize + x, sin(degInRad) * lightSize + y + light.dy);
        }
        glEnd();
        glColor3f(1.0, 1.0, 1.0);
        drawArrow(x + 0.1, y + light.dy, 0.02);
        drawText(light.label, x + 0.15, y + light.dy);
    }

    glColor3f(1.0, 0.0, 0.0);
    glBegin(GL_POLYGON);
    for (int i = 0; i < 360; i++) {
        float degInRad = i * 3.14159 / 180;
        glVertex2f(cos(degInRad) * lightSize + x, sin(degInRad) * lightSize + y - 0.05);
    }
    glEnd();
    glColor3f(0.0, 0.0, 0.0);
    float crossThickness = 0.01;
    glBegin(GL_QUADS);
    glVertex2f(x - crossThickness, y - 0.05 - lightSize);
    glVertex2f(x + crossThickness, y - 0.05 - lightSize);
    glVertex2f(x + crossThickness, y - 0.05 + lightSize);
    glVertex2f(x - crossThickness, y - 0.05 + lightSize);
    glEnd();
    glBegin(GL_QUADS);
    glVertex2f(x - lightSize, y - 0.05 - crossThickness);
    glVertex2f(x + lightSize, y - 0.05 - crossThickness);
    glVertex2f(x + lightSize, y - 0.05 + crossThickness);
    glVertex2f(x - lightSize, y - 0.05 + crossThickness);
    glEnd();

    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_POLYGON);
    for (int i = 0; i < 360; i++) {
        float degInRad = i * 3.14159 / 180;
        glVertex2f(cos(degInRad) * lightSize + x, sin(degInRad) * lightSize + y - 0.15);
    }
    glEnd();
    glColor3f(0.0, 0.0, 0.0);
    glBegin(GL_QUADS);
    glVertex2f(x - lightSize, y - 0.15 - crossThickness);
    glVertex2f(x + lightSize, y - 0.15 - crossThickness);
    glVertex2f(x + lightSize, y - 0.15 + crossThickness);
    glVertex2f(x - lightSize, y - 0.15 + crossThickness);
    glEnd();

    glColor3f(0.0, 1.0, 0.0);
    glBegin(GL_POLYGON);
    for (int i = 0; i < 360; i++) {
        float degInRad = i * 3.14159 / 180;
        glVertex2f(cos(degInRad) * lightSize + x, sin(degInRad) * lightSize + y - 0.25);
    }
    glEnd();
    glColor3f(0.0, 0.0, 0.0);
    float lineThickness = 0.005;
    float lineSpacing = lightSize * 0.5;
    glBegin(GL_QUADS);
    glVertex2f(x - lineThickness, y - 0.25 - lightSize);
    glVertex2f(x + lineThickness, y - 0.25 - lightSize);
    glVertex2f(x + lineThickness, y - 0.25 + lightSize);
    glVertex2f(x - lineThickness, y - 0.25 + lightSize);
    glEnd();
    glBegin(GL_QUADS);
    glVertex2f(x - lineThickness + lineSpacing, y - 0.25 - lightSize);
    glVertex2f(x + lineThickness + lineSpacing, y - 0.25 - lightSize);
    glVertex2f(x + lineThickness + lineSpacing, y - 0.25 + lightSize);
    glVertex2f(x - lineThickness + lineSpacing, y - 0.25 + lightSize);
    glEnd();
}

// Display grass
void grass() {
    float roadRight = 0.4;
    glColor3f(0.0, 0.8, 0.0);
    float grassRight = 1.0;
    glBegin(GL_QUADS);
    glVertex2f(roadRight, -1);
    glVertex2f(grassRight, -1);
    glVertex2f(grassRight, 1);
    glVertex2f(roadRight, 1);
    glEnd();
}

// Zebra Cross
void zebracross() {
    float roadLeft = -0.1, roadRight = 0.4;
    float roadCenter = (roadLeft + roadRight) / 2;
    glColor3f(1.0, 1.0, 1.0);
    float zebraStripeWidth = 0.02;
    float zebraStripeHeight = 0.25;
    float zebraStartX = roadLeft;
    float zebraSpacing = 0.02;
    for (float x = zebraStartX; x <= roadRight - zebraStripeWidth; x += zebraStripeWidth + zebraSpacing) {
        glBegin(GL_QUADS);
        glVertex2f(x, -zebraStripeHeight);
        glVertex2f(x + zebraStripeWidth, -zebraStripeHeight);
        glVertex2f(x + zebraStripeWidth, zebraStripeHeight);
        glVertex2f(x, zebraStripeHeight);
        glEnd();
    }

    glColor3f(1.0, 1.0, 1.0);
    float stripeHeight = 0.3;
    float stripeWidth = 0.03;
    float spaceBetween = 0.2;
    float startY = -0.95;
    while (startY < 1) {
        glBegin(GL_QUADS);
        glVertex2f(roadCenter - stripeWidth / 2, startY);
        glVertex2f(roadCenter + stripeWidth / 2, startY);
        glVertex2f(roadCenter + stripeWidth / 2, startY + stripeHeight);
        glVertex2f(roadCenter - stripeWidth / 2, startY + stripeHeight);
        glEnd();
        startY += stripeHeight + spaceBetween;
    }
}

// FenceWidth
void fenceWidth() {
    float roadLeft = -0.1, roadRight = 0.4;
    glColor3f(0.6, 0.4, 0.2);
    float fenceWidth = 0.02;
    glBegin(GL_QUADS);
    glVertex2f(roadLeft - fenceWidth, -1);
    glVertex2f(roadLeft, -1);
    glVertex2f(roadLeft, 1);
    glVertex2f(roadLeft - fenceWidth, 1);
    glEnd();
}

// Dock start
void dockStart() {
    float roadLeft = -0.1, roadRight = 0.4;
    glColor3f(0.6, 0.4, 0.2);
    float fenceWidth = 0.02;
    glBegin(GL_QUADS);
    glVertex2f(roadLeft - fenceWidth, -1);
    glVertex2f(roadLeft, -1);
    glVertex2f(roadLeft, 1);
    glVertex2f(roadLeft - fenceWidth, 1);
    glEnd();

    glColor3f(0.65, 0.50, 0.39);
    float dockStart = -0.45, dockEnd = roadLeft - fenceWidth;
    glBegin(GL_QUADS);
    glVertex2f(dockStart, -0.1);
    glVertex2f(dockEnd, -0.1);
    glVertex2f(dockEnd, 0.1);
    glVertex2f(dockStart, 0.1);
    glEnd();

    glColor3f(0.0, 0.0, 0.0);
    float stripedoc = 0.005;
    float stripeSpace = 0.02;
    float y1 = -0.1, y2 = 0.1;
    for (float x = dockStart; x < dockEnd; x += stripeSpace) {
        glBegin(GL_QUADS);
        glVertex2f(x, y1);
        glVertex2f(x + stripedoc, y1);
        glVertex2f(x + stripedoc, y2);
        glVertex2f(x, y2);
        glEnd();
    }
}

// Draw series of trees
void displayTrees() {
    drawTrees(treeTexture9, 0.4, 0.55, 0, 0.05, 5, 0.1, 0.1);
    drawTrees(treeTexture2, 0.4, 0.4, 0.1, 0, 6, 0.1, 0.2);
    drawTrees(treeTexture7, 0.4, -0.25, 0.1, 0, 7, 0.1, 0.1);
    drawTrees(treeTexture2, 0.4, -0.35, 0.1, 0, 6, 0.1, 0.2);
    drawTrees(treeTexture9, 0.4, -0.40, 0, -0.05, 11, 0.1, 0.1);
    drawTrees(treeTexture7, 0.4, 0.35, 0.1, 0, 7, 0.1, 0.1);
    drawTrees(treeTexture3, 0.75, 0.75, 0, -0.13, 3, 0.1, 0.1);
    drawTrees(treeTexture3, 0.85, -0.55, 0, -0.17, 3, 0.1, 0.1);
    drawTrees(treeTexture4, 0.83, 0.62, 0, -0.05, 3, 0.1, 0.1);
    drawTrees(treeTexture4, 0.94, -0.55, 0, -0.08, 3, 0.1, 0.1);
    drawTrees(treeTexture6, 0.47, -1, 0.1, 0, 5, 0.15, 0.1);
}

//insert the image into the texture
void loadStartScreenTexture() {
    startScreenTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/start page.png");
}

// Display start screen
void displayStartScreen() {
    glClearColor(0.7, 0.9, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // Enable texturing and blending
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Bind the start screen texture
    glBindTexture(GL_TEXTURE_2D, startScreenTexture);

    // Set the color to white to draw the texture without tinting
    glColor3f(1.0f, 1.0f, 1.0f);

    // Draw the textured quad
    glBegin(GL_QUADS);
    glTexCoord2f(0.0f, 0.0f); glVertex2f(-1.0f, -1.0f);
    glTexCoord2f(1.0f, 0.0f); glVertex2f(1.0f, -1.0f);
    glTexCoord2f(1.0f, 1.0f); glVertex2f(1.0f, 1.0f);
    glTexCoord2f(0.0f, 1.0f); glVertex2f(-1.0f, 1.0f);
    glEnd();

    // Disable texturing and blending
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);

    glFlush();
}

// Display function
void display() {
    updateInvisibility(); // Update invisibility state
    if (isStartScreen) {
        displayStartScreen();
    }
    else if (isGameOver) {
        displayGameOverScreen();
    }
    else {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearColor(0.7, 0.9, 1.0, 1.0);

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        glColor3f(0.5, 0.5, 0.5);
        float roadLeft = -0.1, roadRight = 0.4;
        glBegin(GL_QUADS);
        glVertex2f(roadLeft, -1);
        glVertex2f(roadRight, -1);
        glVertex2f(roadRight, 1);
        glVertex2f(roadLeft, 1);
        glEnd();

        //Grass
        grass();

        //Zebra cross
        zebracross();

        glColor3f(0.0, 0.5, 0.8);
        float waterLeft = -1.0;
        glBegin(GL_QUADS);
        glVertex2f(waterLeft, -1);
        glVertex2f(roadLeft, -1);
        glVertex2f(roadLeft, 1);
        glVertex2f(waterLeft, 1);
        glEnd();

        //Fencing
        fenceWidth();

        //Dock
        dockStart();

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, CoinTexture);
        glColor3f(1.0f, 1.0f, 1.0f);
        for (const auto& coin : coins) {
            if (coin.isActive) {
                glBegin(GL_QUADS);
                glTexCoord2f(0.0, 0.0); glVertex2f(coin.x, coin.y);
                glTexCoord2f(1.0, 0.0); glVertex2f(coin.x + coin.width, coin.y);
                glTexCoord2f(1.0, 1.0); glVertex2f(coin.x + coin.width, coin.y + coin.height);
                glTexCoord2f(0.0, 1.0); glVertex2f(coin.x, coin.y + coin.height);
                glEnd();
            }
        }
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        if (!playerTexture) {
            playerTexture = loadTexture("/Users/chetanvarma/Desktop/GameTesting 6/9b28164db732bbea629542b4dbfb2e13.png");
        }
        glEnable(GL_TEXTURE_2D);
        glColor3f(1.0f, 1.0f, 1.0f);
        glBindTexture(GL_TEXTURE_2D, playerTexture);
        if (!(isInvisible && isBlinking)) { // Draw the player only if not blinking
            glPushMatrix();
            glTranslatef(playerX, playerY, 0.0f);
            glBegin(GL_QUADS);
            glTexCoord2f(0.0, 0.0); glVertex2f(-0.1f, -0.1f);
            glTexCoord2f(1.0, 0.0); glVertex2f(0.1f, -0.1f);
            glTexCoord2f(1.0, 1.0); glVertex2f(0.1f, 0.1f);
            glTexCoord2f(0.0, 1.0); glVertex2f(-0.1f, 0.1f);
            glEnd();
            glPopMatrix();
        }
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);

        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        for (const auto& car : cars) {
            glBindTexture(GL_TEXTURE_2D, carTexture);
            glColor3f(1.0f, 1.0f, 1.0f);
            glBegin(GL_QUADS);
            glTexCoord2f(0.0, 0.0); glVertex2f(car.x, car.y);
            glTexCoord2f(1.0, 0.0); glVertex2f(car.x + car.width, car.y);
            glTexCoord2f(1.0, 1.0); glVertex2f(car.x + car.width, car.y + car.height);
            glTexCoord2f(0.0, 1.0); glVertex2f(car.x, car.y + car.height);
            glEnd();
        }
        glDisable(GL_TEXTURE_2D);

        //draw Traffic Lights
        drawTrafficLight(0.5, 0.3);

        //draw Trees
        displayTrees();

        //draw Ship
        drawTexturedShip(-0.85, 0.6, 0.55);

        // Draw power-ups
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, powerUpTexture);
        glColor3f(1.0f, 1.0f, 1.0f);
        for (const auto& powerUp : powerUps) {
            if (powerUp.isActive) {
                glBegin(GL_QUADS);
                glTexCoord2f(0.0, 0.0); glVertex2f(powerUp.x, powerUp.y);
                glTexCoord2f(1.0, 0.0); glVertex2f(powerUp.x + powerUp.width, powerUp.y);
                glTexCoord2f(1.0, 1.0); glVertex2f(powerUp.x + powerUp.width, powerUp.y + powerUp.height);
                glTexCoord2f(0.0, 1.0); glVertex2f(powerUp.x, powerUp.y + powerUp.height);
                glEnd();
            }
        }
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glColor4f(0.1f, 0.1f, 0.1f, 0.6f);
        glBegin(GL_QUADS);
        glVertex2f(0.55f, 0.88f);
        glVertex2f(0.95f, 0.88f);
        glVertex2f(0.95f, 0.98f);
        glVertex2f(0.55f, 0.98f);
        glEnd();

        glColor3f(1.0f, 1.0f, 1.0f);
        glLineWidth(2.0f);
        glBegin(GL_LINE_LOOP);
        glVertex2f(0.55f, 0.98f);
        glVertex2f(0.95f, 0.98f);
        glVertex2f(0.95f, 0.98f);
        glVertex2f(0.55f, 0.98f);
        glEnd();

        char scoreText[50];
        snprintf(scoreText, sizeof(scoreText), "Score: %d", score);
        glColor3f(1.0f, 0.5f, 0.0f);
        renderBitmapString(0.57f, 0.90f, GLUT_BITMAP_TIMES_ROMAN_24, scoreText);

        glDisable(GL_BLEND);
    }
    glFlush();
    GLenum err;
    while ((err = glGetError()) != GL_NO_ERROR) {
        std::cerr << "OpenGL error: " << err << std::endl;
    }
}

// Initialize function
void init() {
    initTreeTextures();
    glClearColor(0.7, 0.9, 1.0, 1.0);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
}

// Handle key press events
void handleKeypress(unsigned char key, int x, int y) {
    unsigned long currentTime = glutGet(GLUT_ELAPSED_TIME);
    if (currentTime - lastInputTime < inputDebounceInterval) return;
    //if game paused,game over, game started  the keys won't function
    if (!isPaused && !isGameOver && !isStartScreen) {
        switch (key) {
            case 'w':
                if (playerY + 0.1f < 0.25) playerY += 0.1f;
                break;
            case 's':
                if (playerY - 0.1f > -0.25) playerY -= 0.1f;
                break;
            case 'a':
                if (playerX - 0.1f > -0.1) playerX -= 0.1f;
                break;
            case 'd':
                if (playerX + 0.1f < 0.4) playerX += 0.1f;
                break;
        }
        lastInputTime = currentTime;
        glutPostRedisplay();
    }
}

// Handle special key press events
void handleSpecialKeypress(int key, int x, int y) {
    //if game paused,game over, game started  the keys won't function
    if (!isPaused && !isGameOver && !isStartScreen) {
        switch (key) {
            case GLUT_KEY_UP:
                if (playerY + 0.1f < 0.25) {
                    playerY += 0.1f;
                }
                break;
            case GLUT_KEY_DOWN:
                if (playerY - 0.1f > -0.25) {
                    playerY -= 0.1f;
                }
                break;
            case GLUT_KEY_LEFT:
                if (playerX - 0.1f > -0.1) {
                    playerX -= 0.1f;
                }
                break;
            case GLUT_KEY_RIGHT:
                if (playerX + 0.1f < 0.4) {
                    playerX += 0.1f;
                }
                break;
        }
        glutPostRedisplay();
    }
}

// Define minimizeCurrentWindow with the correct linkage
extern "C" void minimizeCurrentWindow() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSApplication sharedApplication].keyWindow miniaturize:nil];
    });
}

// Main function
int main(int argc, char** argv) {
    srand(time(nullptr));
    initGameplayAudio();//gameplay audio initialized
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE | GLUT_RGBA);
    glutInitWindowSize(800, 600);//set window size
    glutInitWindowPosition(100, 100);//set window position
    glutCreateWindow("Dash or Cash");//title
    init();
    initCoinTexture();//coin texture initialized
    initPowerUpTexture();//initialized power up
    loadStartScreenTexture(); // Load the start screen texture
    glutDisplayFunc(display);//call display function
    glutMouseFunc(handleMouseClick);//call mouse click function
    glutPassiveMotionFunc(handleMouseMove);//mouse movement function
    glutKeyboardFunc(handleKeypress);//handles keyboard
    glutSpecialFunc(handleSpecialKeypress);//arrow key functions
    glutTimerFunc(16, updateCarPositions, 0);//updates car positions
    glutTimerFunc(16, updateCoins, 0);//update coins
    glutTimerFunc(16, updatePowerUps, 0); // Update power-ups
    glutMainLoop();
    return 0;
}
