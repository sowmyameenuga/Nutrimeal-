from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date, timedelta
from models import db, ExerciseLog, Profile

exercise_bp = Blueprint("exercise", __name__, url_prefix="/api/exercise")

# MET values mapping for duration-based exercise types and intensities
MET_MAP = {
    "Walking": {"Low": 2.0, "Moderate": 3.5, "High": 4.5},
    "Running": {"Low": 6.0, "Moderate": 8.3, "High": 11.8},
    "Jogging": {"Low": 5.0, "Moderate": 7.0, "High": 9.0},
    "Cycling": {"Low": 4.0, "Moderate": 6.8, "High": 10.0},
    "Swimming": {"Low": 4.5, "Moderate": 6.0, "High": 8.0},
    "Jump Rope": {"Low": 7.0, "Moderate": 10.0, "High": 12.0},
    "Jump Rope (Skipping)": {"Low": 7.0, "Moderate": 10.0, "High": 12.0},
    "Stair Climbing": {"Low": 4.0, "Moderate": 6.0, "High": 8.5},
    "Aerobic / Dance": {"Low": 4.0, "Moderate": 6.0, "High": 7.5},
    "Weight Training": {"Low": 3.0, "Moderate": 5.0, "High": 6.0},
    "Weight Lifting": {"Low": 3.0, "Moderate": 5.0, "High": 6.0},
    "Bodyweight Training": {"Low": 3.0, "Moderate": 4.5, "High": 6.0},
    "Stretching": {"Low": 2.0, "Moderate": 2.5, "High": 3.0},
    "Pilates": {"Low": 2.5, "Moderate": 3.0, "High": 4.0}
}

@exercise_bp.route("/recommend", methods=["GET"])
@jwt_required()
def recommend_exercise():
    """Recommend a personalized exercise based on the user's profile guidelines."""
    user_id = int(get_jwt_identity())
    profile = Profile.query.filter_by(user_id=user_id).first()

    if not profile or not profile.weight_kg or profile.weight_kg <= 0:
        return jsonify({
            "error": "Valid profile data (weight) must be set in your profile to receive recommendations."
        }), 400

    age = profile.age or 30
    weight = profile.weight_kg
    gender = profile.gender or "Male"
    goal = profile.goal or "Maintain Weight"
    activity_level = getattr(profile, "activity_level", "Moderate") or "Moderate"

    # Define the 15 exercises
    all_exercises = [
        "Walking", "Running", "Jogging", "Cycling", "Swimming", "Jump Rope", 
        "Stair Climbing", "Aerobic / Dance", "Weight Training", "Bodyweight Training", 
        "Stretching", "Pilates", "Push-ups", "Squats", "Lunges"
    ]
    reps_exercises = ["Push-ups", "Squats", "Lunges"]

    # Define goal priorities
    goal_priorities = {
        "Weight Loss": [
            "Walking", "Running", "Jogging", "Cycling", "Swimming", "Jump Rope", "Stair Climbing", "Aerobic / Dance"
        ],
        "Fat Loss": [
            "Running", "Jogging", "Jump Rope", "Cycling", "Stair Climbing", "Swimming", "Walking", "Aerobic / Dance"
        ],
        "Weight Gain": [
            "Weight Training", "Squats", "Lunges", "Bodyweight Training", "Push-ups"
        ],
        "Muscle Gain": [
            "Weight Training", "Squats", "Lunges", "Push-ups", "Bodyweight Training"
        ],
        "Maintain Weight": [
            "Walking", "Cycling", "Swimming", "Aerobic / Dance", "Weight Training", 
            "Bodyweight Training", "Pilates", "Stretching", "Push-ups", "Squats", "Lunges"
        ]
    }

    # High / Mod / Low intensity classification of exercises
    exercise_intensities = {
        "Running": "High", "Jogging": "High", "Jump Rope": "High", "Stair Climbing": "High", "Aerobic / Dance": "High",
        "Cycling": "Moderate", "Swimming": "Moderate", "Weight Training": "Moderate", "Bodyweight Training": "Moderate",
        "Push-ups": "Moderate", "Squats": "Moderate", "Lunges": "Moderate",
        "Walking": "Low", "Stretching": "Low", "Pilates": "Low"
    }

    # Base scoring
    scores = {}
    for ex in all_exercises:
        scores[ex] = 0

    # 1. Goal match scoring (Highest priority)
    prioritized_list = goal_priorities.get(goal, goal_priorities["Maintain Weight"])
    for index, ex in enumerate(prioritized_list):
        if ex in scores:
            scores[ex] += 100  # Large base points for matching goal
            scores[ex] += (len(prioritized_list) - index) * 2  # Higher rank in goal priorities gets more points

    # 2. Activity Level matching
    for ex in all_exercises:
        intensity_class = exercise_intensities.get(ex, "Moderate")
        if activity_level in ["Active", "Very Active"]:
            if intensity_class == "High":
                scores[ex] += 20
            elif intensity_class == "Low":
                scores[ex] -= 10
        elif activity_level in ["Sedentary", "Low"]:
            if intensity_class == "Low":
                scores[ex] += 20
            elif intensity_class == "High":
                scores[ex] -= 20
        else: # Light / Moderate
            if intensity_class == "Moderate":
                scores[ex] += 20

    # 3. Age refinement
    if age > 55:
        low_impact = ["Walking", "Swimming", "Stretching", "Pilates"]
        high_impact = ["Running", "Jogging", "Jump Rope", "Stair Climbing"]
        for ex in low_impact:
            if ex in scores:
                scores[ex] += 15
        for ex in high_impact:
            if ex in scores:
                scores[ex] -= 20

    # 4. Weight refinement
    if weight > 90.0:
        joint_heavy = ["Running", "Jogging", "Jump Rope", "Stair Climbing"]
        safe_strength = ["Walking", "Swimming", "Weight Training", "Bodyweight Training", "Push-ups", "Squats", "Lunges"]
        for ex in joint_heavy:
            if ex in scores:
                scores[ex] -= 20
        for ex in safe_strength:
            if ex in scores:
                scores[ex] += 10

    # Sort exercises by score descending
    ranked_exercises = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    best_exercise = ranked_exercises[0][0]

    # Determine recommended intensity
    if activity_level in ["Sedentary", "Low"]:
        recommended_intensity = "Low"
    elif activity_level in ["Active", "Very Active"]:
        recommended_intensity = "High"
    else:
        recommended_intensity = "Moderate"

    # Age adjustment for intensity
    if age > 50 and recommended_intensity == "High":
        recommended_intensity = "Moderate"

    # Determine duration or repetitions
    is_reps = best_exercise in reps_exercises
    if is_reps:
        # Repetitions recommendation
        if activity_level in ["Sedentary", "Low"]:
            amount = 15
        elif activity_level in ["Active", "Very Active"]:
            amount = 40
        else:
            amount = 25
        
        # Age adjustments
        if age > 50:
            amount = max(10, amount - 5)
        
        # Calculate repetitions calorie burn
        factor = {"Low": 0.8, "Moderate": 1.0, "High": 1.2}[recommended_intensity]
        if best_exercise == "Push-ups":
            cal_per_rep = 0.0007 * weight * factor
        elif best_exercise == "Squats":
            cal_per_rep = 0.00137 * weight * factor
        else: # Lunges
            cal_per_rep = 0.0014 * weight * factor
        calories_burned = round(amount * cal_per_rep)
    else:
        # Duration recommendation (minutes)
        if activity_level in ["Sedentary", "Low"]:
            amount = 15
        elif activity_level in ["Active", "Very Active"]:
            amount = 45
        else:
            amount = 30
        
        # Age adjustments
        if age > 65:
            amount = min(20, amount)

        # Calculate duration calorie burn
        met = MET_MAP.get(best_exercise, {}).get(recommended_intensity, 3.5)
        duration_hours = amount / 60.0
        calories_burned = round(met * weight * duration_hours)

    if calories_burned <= 0:
        calories_burned = 1

    return jsonify({
        "exercise_name": best_exercise,
        "duration_minutes": amount,
        "repetitions": amount if is_reps else None,
        "intensity": recommended_intensity,
        "calories_burned": calories_burned,
        "is_repetition_based": is_reps
    }), 200

@exercise_bp.route("/log", methods=["POST"])
@jwt_required()
def log_exercise():
    """Log a new exercise record."""
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    exercise_name = data.get("exercise_name")
    amount = data.get("duration_minutes")  # Can be duration or repetitions
    intensity = data.get("intensity")
    date_str = data.get("date")

    reps_exercises = ["Push-ups", "Squats", "Lunges"]
    is_reps = exercise_name in reps_exercises

    # 1. Validation
    valid_exercises = list(MET_MAP.keys()) + reps_exercises
    if not exercise_name or exercise_name not in valid_exercises:
        return jsonify({"error": "Please select a valid exercise type."}), 400

    try:
        amount = int(amount)
        if amount <= 0:
            raise ValueError
    except (TypeError, ValueError):
        label = "Repetitions" if is_reps else "Duration"
        return jsonify({"error": f"{label} must be greater than 0."}), 400

    if not intensity or intensity not in ["Low", "Moderate", "High"]:
        return jsonify({"error": "Please select a valid intensity (Low, Moderate, High)."}), 400

    # Retrieve user profile and weight
    profile = Profile.query.filter_by(user_id=user_id).first()
    if not profile or not profile.weight_kg or profile.weight_kg <= 0:
        return jsonify({"error": "Valid user weight must be available in your profile before logging exercise."}), 400

    # Parse date (default to today)
    exercise_date = date.today()
    if date_str:
        try:
            exercise_date = date.fromisoformat(date_str)
        except ValueError:
            return jsonify({"error": "Invalid date format. Use YYYY-MM-DD."}), 400

    # 2. Dynamic Calorie Calculation
    weight = profile.weight_kg
    if is_reps:
        factor = {"Low": 0.8, "Moderate": 1.0, "High": 1.2}[intensity]
        if exercise_name == "Push-ups":
            cal_per_rep = 0.0007 * weight * factor
        elif exercise_name == "Squats":
            cal_per_rep = 0.00137 * weight * factor
        else: # Lunges
            cal_per_rep = 0.0014 * weight * factor
        calories_burned = round(amount * cal_per_rep)
    else:
        met = MET_MAP[exercise_name][intensity]
        duration_hours = amount / 60.0
        calories_burned = round(met * weight * duration_hours)

    if calories_burned <= 0:
        calories_burned = 1

    # 3. Save to database
    log = ExerciseLog(
        user_id=user_id,
        exercise_name=exercise_name,
        duration_minutes=amount,  # Storing reps/mins in duration_minutes column
        intensity=intensity,
        calories_burned=calories_burned,
        exercise_date=exercise_date
    )
    db.session.add(log)
    db.session.commit()

    return jsonify({
        "message": "Exercise logged successfully",
        "exercise": log.to_dict()
    }), 200

@exercise_bp.route("/today", methods=["GET"])
@jwt_required()
def get_today_exercises():
    """Get all exercise records logged today."""
    user_id = int(get_jwt_identity())
    today = date.today()

    logs = ExerciseLog.query.filter_by(user_id=user_id, exercise_date=today).all()
    total_burned = sum(log.calories_burned for log in logs)

    return jsonify({
        "date": today.isoformat(),
        "total_calories_burned": total_burned,
        "exercises": [log.to_dict() for log in logs]
    }), 200

@exercise_bp.route("/weekly", methods=["GET"])
@jwt_required()
def get_weekly_exercises():
    """Get daily exercise calorie totals for the current week (Sunday to Saturday)."""
    user_id = int(get_jwt_identity())
    today = date.today()

    # Get Sunday of current week
    idx = (today.weekday() + 1) % 7  # Mon=0 -> index 1, Sun=6 -> index 0
    week_start = today - timedelta(days=idx)
    week_end = week_start + timedelta(days=6)

    logs = ExerciseLog.query.filter(
        ExerciseLog.user_id == user_id,
        ExerciseLog.exercise_date >= week_start,
        ExerciseLog.exercise_date <= week_end
    ).all()

    # Map logs to specific weekdays
    daily_map = {week_start + timedelta(days=i): 0 for i in range(7)}
    for log in logs:
        if log.exercise_date in daily_map:
            daily_map[log.exercise_date] += log.calories_burned

    weekly_data = []
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    for i, (d, cals) in enumerate(daily_map.items()):
        weekly_data.append({
            "date": d.isoformat(),
            "day_name": days[i],
            "calories_burned": cals
        })

    return jsonify({
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "data": weekly_data
    }), 200

@exercise_bp.route("/history", methods=["GET"])
@jwt_required()
def get_exercise_history():
    """Get exercise logs, optionally filtered by a specific date."""
    user_id = int(get_jwt_identity())
    date_str = request.args.get("date")

    if date_str:
        try:
            filter_date = date.fromisoformat(date_str)
            logs = ExerciseLog.query.filter_by(user_id=user_id, exercise_date=filter_date).all()
        except ValueError:
            return jsonify({"error": "Invalid date format. Use YYYY-MM-DD."}), 400
    else:
        logs = ExerciseLog.query.filter_by(user_id=user_id).order_by(ExerciseLog.exercise_date.desc(), ExerciseLog.created_at.desc()).all()

    return jsonify([log.to_dict() for log in logs]), 200
