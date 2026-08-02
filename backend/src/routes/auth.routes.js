const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// POST /api/auth/register - Register a new user profile after Firebase signup
router.post('/register', authController.register);

// POST /api/auth/login - Verify token and return user profile
router.post('/login', verifyToken, authController.login);

// GET /api/auth/me - Get current authenticated user
router.get('/me', verifyToken, authController.getMe);

// POST /api/auth/logout - Logout (revoke refresh tokens)
router.post('/logout', verifyToken, authController.logout);

module.exports = router;
