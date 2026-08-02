const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const { verifyToken } = require('../middleware/auth.middleware');

router.use(verifyToken);

// GET /api/schedule - Get all lessons/sessions
router.get('/', scheduleController.getAllLessons);

// GET /api/schedule/:id - Get a specific lesson
router.get('/:id', scheduleController.getLessonById);

// POST /api/schedule - Create a new lesson/session
router.post('/', scheduleController.createLesson);

// PUT /api/schedule/:id - Update a lesson
router.put('/:id', scheduleController.updateLesson);

// DELETE /api/schedule/:id - Cancel/delete a lesson
router.delete('/:id', scheduleController.deleteLesson);

module.exports = router;
