const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// All user routes require authentication
router.use(verifyToken);

// GET /api/users - List all users (admin)
router.get('/', usersController.getAllUsers);

// GET /api/users/:id - Get a specific user
router.get('/:id', usersController.getUserById);

// PUT /api/users/:id - Update user profile
router.put('/:id', usersController.updateUser);

// DELETE /api/users/:id - Delete a user
router.delete('/:id', usersController.deleteUser);

module.exports = router;
