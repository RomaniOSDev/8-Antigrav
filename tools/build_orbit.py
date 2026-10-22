#!/usr/bin/env python3
import json, os

moves = []

def add(i, name, cat, eq, diff, summary, cues, mistakes, breath, primary, secondary, reg, prog, b, m, h, timed=False):
    moves.append({
        "id": i, "name": name, "category": cat, "equipment": eq, "difficulty": diff,
        "summary": summary, "cues": cues, "mistakes": mistakes, "breathing": breath,
        "primary": primary, "secondary": secondary, "regression": reg, "progression": prog,
        "beginTarget": b, "midTarget": m, "highTarget": h, "timed": timed,
    })

add("wall-push", "Wall Push-Up", "Push", "none", 1,
    "Hands on a wall, body in a straight line, bend the elbows and press back.",
    ["Hands a little wider than shoulders", "Ribs stay down", "Push the wall away"],
    ["Hips sag", "Elbows flare wildly", "Only the neck moves"],
    "Inhale as you bend, exhale as you press.", ["chest", "shoulders"], ["triceps"], None, "incline-push", 12, 20, 30)
add("incline-push", "Incline Push-Up", "Push", "none", 1,
    "Hands on a sturdy raised surface, body straight, lower the chest and press away.",
    ["Step feet back until the body is one line", "Chest travels between the hands", "Finish with arms long"],
    ["Hips pike up", "Shoulders shrug to the ears", "Bouncing off the surface"],
    "Exhale through the press.", ["chest"], ["shoulders", "triceps"], "wall-push", "knee-push", 8, 12, 20)
add("knee-push", "Knee Push-Up", "Push", "none", 1,
    "Knees down, hands under shoulders, lower and press while the torso stays rigid.",
    ["Knees, hips, and shoulders line up", "Look slightly ahead", "Full elbow bend you can control"],
    ["Hips fold", "Hands too far forward", "Half reps only"],
    "Steady breath, no breath holding.", ["chest", "triceps"], ["shoulders"], "incline-push", "push-up", 8, 12, 20)
add("push-up", "Push-Up", "Push", "none", 2,
    "Hands under shoulders, toes planted, lower the chest and press the floor away.",
    ["Brace before you bend", "Elbows near forty-five degrees", "Chest and hips arrive together"],
    ["Sagging hips", "Head leading", "Locked elbows slammed"],
    "Inhale down, exhale up.", ["chest", "triceps"], ["shoulders", "abs"], "knee-push", "wide-push", 6, 12, 20)
add("wide-push", "Wide Push-Up", "Push", "none", 2,
    "Hands set wider than the shoulders to bias the chest, then press with a straight body.",
    ["Spread fingers", "Keep the neck long", "Do not let the hips drop"],
    ["Hands so wide the shoulders pinch", "Shallow range"],
    "Exhale as the chest leaves the floor.", ["chest"], ["shoulders"], "push-up", "diamond-push", 6, 10, 16)
add("diamond-push", "Diamond Push-Up", "Push", "none", 3,
    "Hands close under the chest so thumbs and fingers form a diamond, then press.",
    ["Elbows track back", "Body stays one piece", "Stop if the wrists complain and widen slightly"],
    ["Flaring elbows", "Hips sagging", "Hands collapsing"],
    "Shorter breaths, still smooth.", ["triceps", "chest"], ["shoulders"], "push-up", "archer-push", 4, 8, 12)
add("decline-push", "Decline Push-Up", "Push", "none", 3,
    "Feet raised on a low step, hands on the floor, press with the shoulders carrying more load.",
    ["Step only as high as you can keep a straight line", "Do not shrug", "Lower under control"],
    ["Feet too high too soon", "Head dropping", "Bouncing"],
    "Exhale on the press.", ["shoulders", "chest"], ["triceps"], "push-up", "pike-push", 5, 8, 14)
add("archer-push", "Archer Push-Up", "Push", "none", 3,
    "One arm bends while the other stays straighter, then switch, like drawing a bow.",
    ["Shift the chest toward the bending arm", "Keep both hands planted", "Move slowly"],
    ["Twisting the hips", "Collapsing the straight arm"],
    "Exhale as you press back to center.", ["chest", "shoulders"], ["triceps"], "wide-push", "pseudo-planche", 3, 6, 8)
add("pike-push", "Pike Push-Up", "Push", "none", 3,
    "Hips high, body in a pike, bend the elbows so the head travels toward the floor, then press.",
    ["Hands shoulder width", "Weight stays in the palms", "Look back toward the feet"],
    ["Rounding the back", "Elbows flying out", "Dropping onto the head"],
    "Inhale to lower, exhale to press.", ["shoulders"], ["triceps"], "decline-push", "pseudo-planche", 4, 8, 12)
add("pseudo-planche", "Pseudo-Planche Push-Up", "Push", "none", 3,
    "Hands by the hips, fingers forward or slightly out, lean until the shoulders pass the wrists, then bend and press.",
    ["Lean before you bend", "Lock the ribs", "Short range is honest range"],
    ["Bending with no lean", "Wrists dumped", "Hips sagging"],
    "Brace and use short exhales.", ["shoulders", "chest"], ["abs"], "pike-push", None, 3, 6, 8)
add("bench-dip", "Bench Dip", "Push", "none", 2,
    "Hands on a sturdy seat behind you, feet forward, bend the elbows and press.",
    ["Shoulders stay down", "Elbows point back", "Stop if the front of the shoulder pinches"],
    ["Shrugging", "Dropping too deep", "A wobbly seat"],
    "Exhale as you press up.", ["triceps"], ["chest", "shoulders"], "knee-push", "bar-dip", 8, 12, 16)
add("bar-dip", "Parallel Bar Dip", "Push", "dip", 3,
    "Support yourself on bars, lower until the shoulders stay comfortable, then press tall.",
    ["Slight forward lean", "Elbows back", "Do not bounce the bottom"],
    ["Shoulders rolling forward", "Half reps", "Kipping"],
    "Inhale down, exhale up.", ["chest", "triceps"], ["shoulders"], "bench-dip", None, 3, 6, 10)

add("scap-pull", "Scapular Pull", "Pull", "bar", 1,
    "Hang and lift the shoulders away from the ears without bending the elbows, then lower.",
    ["Arms stay long", "Chest rises slightly", "Small honest range"],
    ["Bending the elbows", "Swinging", "Shrugging hard"],
    "Exhale as the shoulders set down.", ["back"], ["shoulders"], None, "aus-row", 6, 10, 15)
add("dead-hang", "Dead Hang", "Pull", "bar", 1,
    "Hang from a bar with a grip you can hold, ribs quiet, shoulders active enough to feel safe.",
    ["Thumb around the bar", "Soft knees", "Stop if grip slips"],
    ["Passive shoulders if they hurt", "Holding the breath", "Swinging"],
    "Slow nasal breaths for the whole hold.", ["back", "shoulders"], ["biceps"], "scap-pull", "neg-pull", 20, 35, 50, True)
add("aus-row", "Australian Row", "Pull", "bar", 1,
    "Body straight under a low bar, pull the chest toward the bar, then lower.",
    ["Heels down", "Squeeze the shoulder blades", "Straight line from heel to head"],
    ["Hips sagging", "Only bending the neck", "Half pulls"],
    "Exhale as you pull.", ["back", "biceps"], ["shoulders"], "scap-pull", "neg-pull", 8, 12, 16)
add("towel-row", "Towel Row", "Pull", "none", 2,
    "A towel looped on a closed door, lean back, and pull the chest toward the door.",
    ["Test the door before you lean", "Elbows travel back", "Body stays rigid"],
    ["A door that can swing", "Shrugging", "Using momentum"],
    "Exhale on the pull.", ["back"], ["biceps"], "aus-row", "neg-pull", 8, 12, 16)
add("neg-pull", "Negative Pull-Up", "Pull", "bar", 2,
    "Start with the chin over the bar and lower yourself as slowly as you can.",
    ["Jump or step to the top", "Three to five slow seconds down", "Full hang at the bottom"],
    ["Dropping", "Half range", "Kicking"],
    "Exhale on the way down or breathe quietly through it.", ["back", "biceps"], ["shoulders"], "aus-row", "pull-up", 3, 5, 8)
add("pull-up", "Pull-Up", "Pull", "bar", 3,
    "Hang, pull until the chin clears the bar, lower with control.",
    ["Start from a still hang", "Drive elbows down", "No swing"],
    ["Half reps", "Neck reaching", "Kipping unless you chose it"],
    "Exhale as you pull.", ["back", "biceps"], ["shoulders"], "neg-pull", "wide-pull", 3, 6, 12)
add("chin-up", "Chin-Up", "Pull", "bar", 2,
    "Palms face you, pull the chin over the bar, lower until the arms are long.",
    ["Grip just inside shoulder width", "Ribs quiet", "Smooth tempo"],
    ["Swinging", "Cutting the bottom short"],
    "Exhale up, inhale down.", ["biceps", "back"], ["shoulders"], "aus-row", "pull-up", 3, 6, 12)
add("wide-pull", "Wide Pull-Up", "Pull", "bar", 3,
    "A wider grip shifts work toward the upper back. Pull the chest toward the bar.",
    ["Do not go so wide the shoulders pinch", "Lead with the chest", "Control the lower"],
    ["Shrugging", "Tiny range"],
    "Exhale through the pull.", ["back"], ["biceps", "shoulders"], "pull-up", "lsit-pull", 2, 5, 8)
add("lsit-pull", "L-Sit Pull-Up", "Pull", "bar", 3,
    "Hold the legs forward in an L, or tuck them, and pull the chin over the bar.",
    ["Legs only as high as the back stays honest", "No swing", "Lower all the way"],
    ["Kicking the legs for momentum", "Rounding hard"],
    "Brace, then exhale on the pull.", ["back", "abs"], ["biceps"], "pull-up", None, 2, 4, 6)
add("band-apart", "Band Pull-Apart", "Pull", "band", 1,
    "Hold a band at shoulder height and pull the hands apart until the band touches the chest.",
    ["Soft elbows", "Shoulders down", "Pause when the band meets the chest"],
    ["Shrugging", "Bending the wrists", "Using a band you cannot finish"],
    "Exhale as the hands separate.", ["back", "shoulders"], ["triceps"], None, "aus-row", 10, 15, 25)

add("squat", "Bodyweight Squat", "Legs", "none", 1,
    "Feet planted, sit the hips back and down, then stand tall.",
    ["Knees track over the toes", "Chest stays proud", "Heels stay down"],
    ["Knees collapsing in", "Heels rising", "Stopping halfway"],
    "Inhale down, exhale up.", ["quads", "glutes"], ["abs"], None, "split-squat", 12, 20, 30)
add("jump-squat", "Jump Squat", "Legs", "none", 2,
    "Squat, then jump, and land softly back into the next squat.",
    ["Quiet feet", "Knees track", "Stand tall before you leave the floor"],
    ["Stiff landings", "Knees caving", "Looking at the feet"],
    "Exhale as you leave the floor.", ["quads", "glutes"], ["calves"], "squat", "split-squat", 6, 10, 14)
add("split-squat", "Split Squat", "Legs", "none", 2,
    "One foot forward, one back, lower the rear knee, then press through the front foot.",
    ["Front heel down", "Torso tall", "Even reps each side"],
    ["Front knee collapsing", "Bouncing the knee", "Short stance that tips you"],
    "Exhale as you rise.", ["quads", "glutes"], ["hamstrings"], "squat", "bulg-split", 8, 12, 16)
add("rev-lunge", "Reverse Lunge", "Legs", "none", 2,
    "Step backward, lower, and return to stand. Switch sides.",
    ["Step long enough to stay balanced", "Front heel heavy", "Torso quiet"],
    ["Tiny steps", "Knee diving in", "Rushing the return"],
    "Exhale on the way up.", ["quads", "glutes"], ["hamstrings"], "split-squat", "bulg-split", 8, 12, 16)
add("glute-bridge", "Glute Bridge", "Legs", "none", 1,
    "On your back, feet flat, press the hips up and squeeze, then lower.",
    ["Ribs down", "Drive through the heels", "Pause at the top"],
    ["Overarching the low back", "Feet too far", "Rushing"],
    "Exhale as the hips rise.", ["glutes"], ["hamstrings"], None, "sl-bridge", 10, 15, 20)
add("sl-bridge", "Single-Leg Glute Bridge", "Legs", "none", 2,
    "Bridge on one foot, the other leg long, hips level.",
    ["Hips stay square", "Heel drives", "Slow lower"],
    ["Hip drop", "Pushing with the neck"],
    "Exhale up.", ["glutes"], ["hamstrings"], "glute-bridge", "bulg-split", 6, 10, 14)
add("step-up", "Step-Up", "Legs", "none", 2,
    "Step onto a sturdy low platform and stand tall, then lower.",
    ["Whole foot on the step", "Drive through the top leg", "Control the way down"],
    ["Pushing off the back leg only", "A wobbly platform"],
    "Exhale as you stand.", ["quads", "glutes"], ["calves"], "split-squat", "bulg-split", 8, 12, 16)
add("bulg-split", "Bulgarian Split Squat", "Legs", "none", 3,
    "Rear foot elevated, lower the back knee, press through the front heel.",
    ["Shorten the stance if the knee hurts", "Torso tall", "Even sides"],
    ["Rear foot too high", "Front heel lifting", "Falling inward"],
    "Exhale to stand.", ["quads", "glutes"], ["hamstrings"], "split-squat", "asst-pistol", 6, 10, 12)
add("wall-sit", "Wall Sit", "Legs", "none", 1,
    "Back on a wall, thighs near level, hold.",
    ["Knees over ankles", "Back flat", "Breathe"],
    ["Knees past the toes if it hurts", "Holding the breath"],
    "Quiet breaths for the whole hold.", ["quads"], ["glutes"], "squat", "split-squat", 20, 40, 60, True)
add("calf-raise", "Calf Raise", "Legs", "none", 1,
    "Rise onto the balls of the feet, pause, and lower.",
    ["Slow lower", "Straight knees if that is the goal", "Use a wall for balance if needed"],
    ["Bouncing", "Rolling the ankles out"],
    "Exhale as you rise.", ["calves"], ["quads"], None, "jump-squat", 12, 20, 30)
add("asst-pistol", "Assisted Pistol Squat", "Legs", "none", 3,
    "Hold a door frame, squat on one leg as deep as you can own, then stand.",
    ["Heel stays heavy", "Knee tracks", "Use the hands only as much as you need"],
    ["Collapsing at the bottom", "Knee caving"],
    "Exhale to stand.", ["quads", "glutes"], ["abs"], "bulg-split", "pistol", 3, 5, 8)
add("pistol", "Pistol Squat", "Legs", "none", 3,
    "Squat on one leg to a depth you control and stand without the other foot touching.",
    ["Arms forward for balance", "Heel down", "Smooth tempo"],
    ["Dropping into the bottom", "Knee falling in"],
    "Exhale on the rise.", ["quads", "glutes"], ["abs"], "asst-pistol", None, 2, 3, 5)

add("plank", "Plank", "Core", "none", 1,
    "Forearms or hands down, body one line, hold.",
    ["Ribs down", "Squeeze the glutes", "Look at the floor"],
    ["Hips sagging or piking", "Holding the breath"],
    "Quiet breaths.", ["abs"], ["shoulders", "glutes"], None, "side-plank", 20, 40, 60, True)
add("side-plank", "Side Plank", "Core", "none", 2,
    "On one forearm, hips lifted, body straight from ear to ankle.",
    ["Hips forward", "Shoulder over elbow", "Switch sides"],
    ["Hips rolling back", "Neck craning"],
    "Breathe into the side that is working.", ["obliques"], ["shoulders"], "plank", "dead-bug", 15, 30, 45, True)
add("dead-bug", "Dead Bug", "Core", "none", 1,
    "On your back, arms and knees up, reach the opposite arm and leg away while the low back stays down.",
    ["Exhale as the limbs go long", "Move slowly", "Range only as far as the back stays quiet"],
    ["Arching", "Rushing"],
    "Exhale on the reach.", ["abs"], ["hips"], "plank", "bird-dog", 6, 10, 14)
add("bird-dog", "Bird Dog", "Core", "none", 1,
    "On hands and knees, reach one arm and the opposite leg, then switch.",
    ["Hips level", "Long spine", "Pause"],
    ["Rotating the pelvis", "Looking up hard"],
    "Exhale as you reach.", ["abs", "back"], ["glutes"], "dead-bug", "hollow-hold", 6, 10, 12)
add("hollow-hold", "Hollow Hold", "Core", "none", 2,
    "On your back, low back pressed down, arms and legs long and slightly off the floor.",
    ["Ribs heavy", "Chin slightly tucked", "Scale the legs higher if needed"],
    ["Back peeling off the floor", "Holding the breath"],
    "Small breaths.", ["abs"], ["hips"], "dead-bug", "hollow-rock", 15, 25, 40, True)
add("hollow-rock", "Hollow Rock", "Core", "none", 3,
    "From a hollow shape, rock a short distance without losing the low back.",
    ["Small rocks", "Shape first", "Stop when the back arches"],
    ["Big swings", "Neck strain"],
    "Exhale to reset the shape.", ["abs"], ["hips"], "hollow-hold", "leg-raise", 8, 12, 20)
add("leg-raise", "Lying Leg Raise", "Core", "none", 2,
    "On your back, lift straight legs and lower them without the back arching.",
    ["Hands can pin the hips lightly", "Control the lower", "Bend the knees to regress"],
    ["Swinging", "Back arching"],
    "Exhale as the legs lower.", ["abs"], ["hips"], "hollow-hold", "hang-knee", 8, 12, 16)
add("hang-knee", "Hanging Knee Raise", "Core", "bar", 2,
    "Hang, lift the knees, lower without swinging.",
    ["Start still", "Posterior tilt", "No kick"],
    ["Swinging", "Only bending the hips a little"],
    "Exhale as the knees rise.", ["abs"], ["biceps"], "leg-raise", "hang-leg", 8, 12, 16)
add("hang-leg", "Hanging Leg Raise", "Core", "bar", 3,
    "Hang and lift straight legs as high as the back stays honest.",
    ["No swing", "Control down", "Bend knees if the shape breaks"],
    ["Using momentum", "Shrugging hard"],
    "Exhale up.", ["abs"], ["shoulders"], "hang-knee", "lsit-tuck", 6, 10, 14)
add("lsit-tuck", "L-Sit Tuck", "Core", "none", 2,
    "Hands on the floor or low bars, knees tucked, hips lifted, hold.",
    ["Push the floor away", "Knees toward the chest", "Shoulders down"],
    ["Sagging", "Holding the breath"],
    "Short breaths.", ["abs", "shoulders"], ["triceps"], "plank", "lsit", 10, 20, 30, True)
add("lsit", "L-Sit", "Core", "none", 3,
    "Hands down, legs straight forward, hips off the floor.",
    ["Point or flex the feet consistently", "Push tall", "Use a tuck if the legs drop"],
    ["Bent arms collapsing", "Legs dragging"],
    "Brace and breathe.", ["abs", "shoulders"], ["quads"], "lsit-tuck", None, 5, 10, 15, True)
add("climbers", "Mountain Climbers", "Core", "none", 2,
    "From a plank, drive one knee in, then the other, at a pace you can keep honest.",
    ["Hips quiet", "Hands under shoulders", "Soft feet"],
    ["Bouncing the hips", "Holding the breath"],
    "Match breath to a steady count.", ["abs"], ["shoulders", "quads"], "plank", "dead-bug", 20, 30, 40)

add("frog", "Frog Stand", "Balance", "none", 2,
    "Squat, place hands, rest knees on the arms, and lean until the feet hover.",
    ["Look forward", "Fingers spread", "Lean slowly"],
    ["Diving forward", "Hands too close"],
    "Hold a breath pattern, do not gasp.", ["shoulders", "abs"], ["triceps"], None, "crow", 10, 20, 30, True)
add("crow", "Crow Pose", "Balance", "none", 2,
    "Knees high on the arms, lean, and lift the feet.",
    ["Elbows bent slightly", "Gaze forward", "Come down before you fall"],
    ["Elbows splaying", "Looking at the floor only"],
    "Slow breaths.", ["shoulders", "abs"], ["chest"], "frog", "wall-hs", 10, 20, 30, True)
add("wall-hs", "Wall Handstand Hold", "Balance", "none", 2,
    "Kick or walk up a wall and hold a straight line as well as you can.",
    ["Hands shoulder width", "Push the floor", "Belly tight"],
    ["Banana back", "Locked breath"],
    "Breathe in the hold.", ["shoulders"], ["abs", "triceps"], "pike-push", "c2w-hs", 15, 30, 45, True)
add("c2w-hs", "Chest-to-Wall Handstand", "Balance", "none", 3,
    "Face the wall, hands close, walk the feet up until the chest is near the wall.",
    ["Hands close to the wall", "Ribs in", "Exit with control"],
    ["Hands too far", "Crashing down"],
    "Steady breaths.", ["shoulders"], ["abs"], "wall-hs", "hs-taps", 20, 40, 60, True)
add("hs-taps", "Handstand Shoulder Taps", "Balance", "none", 3,
    "In a wall handstand, shift and tap one shoulder, then the other.",
    ["Tiny shifts", "Fingers grip the floor", "Keep the hips over the hands"],
    ["Big swings", "Bending the hips each tap"],
    "Exhale on each tap.", ["shoulders"], ["abs"], "c2w-hs", "planche-lean", 4, 8, 12)
add("planche-lean", "Tuck Planche Lean", "Balance", "none", 3,
    "Hands by the hips, lean forward with knees tucked until the feet lighten.",
    ["Protract the shoulders", "Short leans", "Wrists comfortable"],
    ["Bending the arms immediately", "Dumping the wrists"],
    "Brace, short breaths.", ["shoulders", "abs"], ["chest"], "pseudo-planche", None, 10, 20, 30, True)

add("cat-cow", "Cat-Cow", "Flow", "none", 1,
    "On hands and knees, round the spine, then gently extend, moving with the breath.",
    ["Slow", "Move the whole spine", "Stay in a pain-free range"],
    ["Forcing the neck", "Rushing"],
    "Inhale to open, exhale to round.", ["back"], ["abs"], None, "t-spine", 6, 8, 10)
add("wgs", "World's Greatest Stretch", "Flow", "none", 1,
    "From a lunge, place a hand inside the front foot, rotate the chest open, then switch.",
    ["Back knee down if you need it", "Long spine", "Breathe in the open position"],
    ["Collapsing the front knee", "Holding the breath"],
    "Exhale as you rotate open.", ["hips", "back"], ["shoulders"], "cat-cow", "hip-9090", 4, 6, 8)
add("hip-9090", "90/90 Hip Switch", "Flow", "none", 1,
    "Sit with both knees bent near ninety degrees and rotate the legs to the other side.",
    ["Tall chest", "Use hands if needed", "Smooth switch"],
    ["Falling backward", "Forcing a pinch"],
    "Exhale through the switch.", ["hips"], ["abs"], "wgs", "deep-squat", 6, 8, 12)
add("t-spine", "Thoracic Rotation", "Flow", "none", 1,
    "Side-lying or hands and knees, rotate the upper back while the hips stay quieter.",
    ["Follow the hand with the eyes", "Small range is fine", "Breathe"],
    ["Yanking the neck", "Rotating only the low back"],
    "Inhale to open.", ["back"], ["shoulders"], "cat-cow", "wgs", 6, 8, 10)
add("deep-squat", "Deep Squat Hold", "Flow", "none", 1,
    "Sit into a deep squat you can breathe in, heels down or supported.",
    ["Knees track", "Chest up", "Hold a rail if the heels rise and that bothers you"],
    ["Bouncing", "Pain in the knees"],
    "Long breaths.", ["hips", "quads"], ["back"], "squat", "hamstring", 20, 40, 60, True)
add("hamstring", "Hamstring Stretch", "Flow", "none", 1,
    "One leg long, hinge until you feel the back of the thigh, and breathe.",
    ["Soft knee if needed", "Long spine", "No bouncing"],
    ["Rounding hard to chase the toes", "Holding the breath"],
    "Exhale to settle.", ["hamstrings"], ["back"], "deep-squat", "child", 20, 30, 45, True)
add("child", "Child's Pose", "Flow", "none", 1,
    "Knees apart or together, hips toward the heels, arms long, breathe into the back.",
    ["Forehead supported if needed", "Soft belly", "Stay only as long as it feels kind"],
    ["Forcing the hips down", "Holding the breath"],
    "Slow breaths into the back.", ["back"], ["shoulders"], "hamstring", "shoulder-circles", 20, 40, 60, True)
add("shoulder-circles", "Shoulder Circles", "Flow", "none", 1,
    "Stand or sit and draw slow circles with the shoulders, both directions.",
    ["Small then larger", "Jaw soft", "Even sides"],
    ["Shrugging and holding", "Rushing"],
    "Match one breath to a few circles.", ["shoulders"], ["back"], "child", "cat-cow", 8, 12, 16)

programs = []

def prog(pid, name, summary, weeks, dpw, diff, needs, minutes, days):
    programs.append({
        "id": pid, "name": name, "summary": summary, "weeks": weeks, "daysPerWeek": dpw,
        "difficulty": diff, "needs": needs, "minutes": minutes, "days": days,
    })

def day(pid, n, title, items):
    return {"id": f"{pid}-d{n}", "title": title, "items": [
        {"id": f"{pid}-d{n}-i{k}", "moveId": m, "sets": s, "amount": a, "rest": r}
        for k, (m, s, a, r) in enumerate(items)
    ]}

found = []
cycles = [
    ("Full body A", [("squat", 3, 8, 45), ("incline-push", 3, 8, 45), ("towel-row", 3, 8, 45), ("plank", 3, 20, 30)]),
    ("Full body B", [("glute-bridge", 3, 10, 40), ("knee-push", 3, 8, 45), ("band-apart", 3, 12, 30), ("dead-bug", 3, 8, 30)]),
    ("Full body C", [("rev-lunge", 3, 6, 45), ("wall-push", 3, 10, 40), ("bird-dog", 3, 8, 30), ("glute-bridge", 2, 12, 30)]),
]
n = 1
for week in range(4):
    for title, items in cycles:
        bumped = [(m, s, a + week, r) for m, s, a, r in items]
        found.append(day("found", n, f"Week {week+1} {title}", bumped))
        n += 1
prog("found", "Foundations", "Four weeks, three days, a full body start for new trainees.", 4, 3, "Beginner", "none", 28, found)

ladder = []
for i in range(1, 31):
    reps = 4 + (i // 2)
    move = "knee-push" if i < 8 else ("push-up" if i < 20 else "diamond-push")
    sets = 3 if i < 15 else 4
    ladder.append(day("ladder", i, f"Day {i}", [(move, sets, reps, 40), ("plank", 2, 20 + i // 3, 30)]))
prog("ladder", "Push-Up Ladder", "Thirty short days that raise pushing volume a little at a time.", 5, 7, "Beginner", "none", 16, ladder)

pull = []
pull_cycle = [
    ("Hang and row", [("dead-hang", 3, 20, 40), ("aus-row", 4, 8, 45), ("scap-pull", 3, 8, 30)]),
    ("Lower slowly", [("neg-pull", 4, 3, 60), ("aus-row", 3, 10, 45), ("band-apart", 3, 12, 30)]),
    ("Pull practice", [("pull-up", 5, 2, 70), ("chin-up", 3, 3, 60), ("dead-hang", 2, 25, 40)]),
]
n = 1
for week in range(6):
    for title, items in pull_cycle:
        grown = []
        for m, s, a, r in items:
            grown.append((m, s, a + (week if m != "pull-up" else min(week, 3)), r))
        pull.append(day("pull", n, f"Week {week+1} {title}", grown))
        n += 1
prog("pull", "Pull-Up Path", "Six weeks, three days, from hangs toward stricter pulls. Needs a bar.", 6, 3, "Intermediate", "bar", 30, pull)

core = []
for i in range(1, 22):
    core.append(day("core", i, f"Day {i}", [
        ("plank", 3, 20 + i, 25),
        ("dead-bug", 3, 6 + i // 4, 25),
        ("hollow-hold", 3, 12 + i // 2, 25),
        ("climbers", 2, 16 + i // 2, 30),
    ]))
prog("core", "Core 21", "Twenty-one short days for bracing and control.", 3, 7, "Beginner", "none", 12, core)

flow = []
flow_sets = [
    [("cat-cow", 2, 8, 20), ("wgs", 2, 4, 20), ("hip-9090", 2, 8, 20), ("child", 2, 30, 20)],
    [("t-spine", 2, 8, 20), ("deep-squat", 2, 30, 20), ("hamstring", 2, 30, 20), ("shoulder-circles", 2, 10, 15)],
]
for i in range(1, 15):
    flow.append(day("flow", i, f"Day {i}", flow_sets[(i - 1) % 2]))
prog("flow", "Mobility Reset", "Fourteen days, about ten minutes, to keep joints moving.", 2, 7, "Beginner", "none", 10, flow)

paths = [
    {"id": "push", "name": "Push", "summary": "From incline presses toward a leaning planche push-up.", "nodes": [
        {"id": "push-1", "title": "Incline Push-Up", "moveId": "incline-push", "target": 15, "timed": False, "perSide": False, "how": "Log 15 clean incline push-ups.", "flowCount": 0},
        {"id": "push-2", "title": "Push-Up", "moveId": "push-up", "target": 15, "timed": False, "perSide": False, "how": "Log 15 push-ups with a straight body.", "flowCount": 0},
        {"id": "push-3", "title": "Diamond Push-Up", "moveId": "diamond-push", "target": 12, "timed": False, "perSide": False, "how": "Log 12 diamond push-ups.", "flowCount": 0},
        {"id": "push-4", "title": "Archer Push-Up", "moveId": "archer-push", "target": 6, "timed": False, "perSide": True, "how": "Log 6 each side. Enter the weaker side.", "flowCount": 0},
        {"id": "push-5", "title": "Pseudo-Planche Push-Up", "moveId": "pseudo-planche", "target": 8, "timed": False, "perSide": False, "how": "Log 8 leaning push-ups.", "flowCount": 0},
    ]},
    {"id": "pull", "name": "Pull", "summary": "From a hang toward an L-sit pull-up.", "nodes": [
        {"id": "pull-1", "title": "Dead Hang", "moveId": "dead-hang", "target": 45, "timed": True, "perSide": False, "how": "Hold a dead hang for 45 seconds.", "flowCount": 0},
        {"id": "pull-2", "title": "Australian Row", "moveId": "aus-row", "target": 15, "timed": False, "perSide": False, "how": "Log 15 rows.", "flowCount": 0},
        {"id": "pull-3", "title": "Pull-Up", "moveId": "pull-up", "target": 5, "timed": False, "perSide": False, "how": "Log 5 strict pull-ups.", "flowCount": 0},
        {"id": "pull-4", "title": "Pull-Up 12", "moveId": "pull-up", "target": 12, "timed": False, "perSide": False, "how": "Log 12 strict pull-ups.", "flowCount": 0},
        {"id": "pull-5", "title": "L-Sit Pull-Up", "moveId": "lsit-pull", "target": 5, "timed": False, "perSide": False, "how": "Log 5 pull-ups with the legs forward or tucked.", "flowCount": 0},
    ]},
    {"id": "legs", "name": "Legs", "summary": "From squats toward a pistol squat.", "nodes": [
        {"id": "legs-1", "title": "Squat", "moveId": "squat", "target": 30, "timed": False, "perSide": False, "how": "Log 30 squats.", "flowCount": 0},
        {"id": "legs-2", "title": "Split Squat", "moveId": "split-squat", "target": 12, "timed": False, "perSide": True, "how": "Log 12 each side. Enter the weaker side.", "flowCount": 0},
        {"id": "legs-3", "title": "Bulgarian Split Squat", "moveId": "bulg-split", "target": 10, "timed": False, "perSide": True, "how": "Log 10 each side.", "flowCount": 0},
        {"id": "legs-4", "title": "Assisted Pistol", "moveId": "asst-pistol", "target": 5, "timed": False, "perSide": True, "how": "Log 5 each side.", "flowCount": 0},
        {"id": "legs-5", "title": "Pistol Squat", "moveId": "pistol", "target": 3, "timed": False, "perSide": True, "how": "Log 3 each side.", "flowCount": 0},
    ]},
    {"id": "core", "name": "Core", "summary": "From a plank toward an L-sit.", "nodes": [
        {"id": "core-1", "title": "Plank", "moveId": "plank", "target": 60, "timed": True, "perSide": False, "how": "Hold a plank for 60 seconds.", "flowCount": 0},
        {"id": "core-2", "title": "Hollow Hold", "moveId": "hollow-hold", "target": 30, "timed": True, "perSide": False, "how": "Hold a hollow shape for 30 seconds.", "flowCount": 0},
        {"id": "core-3", "title": "Hanging Knee Raise", "moveId": "hang-knee", "target": 15, "timed": False, "perSide": False, "how": "Log 15 hanging knee raises.", "flowCount": 0},
        {"id": "core-4", "title": "L-Sit Tuck", "moveId": "lsit-tuck", "target": 15, "timed": True, "perSide": False, "how": "Hold a tuck L-sit for 15 seconds.", "flowCount": 0},
        {"id": "core-5", "title": "L-Sit", "moveId": "lsit", "target": 10, "timed": True, "perSide": False, "how": "Hold an L-sit for 10 seconds.", "flowCount": 0},
    ]},
    {"id": "balance", "name": "Balance", "summary": "From a frog stand toward a freestanding handstand.", "nodes": [
        {"id": "bal-1", "title": "Frog Stand", "moveId": "frog", "target": 20, "timed": True, "perSide": False, "how": "Hold a frog stand for 20 seconds.", "flowCount": 0},
        {"id": "bal-2", "title": "Crow Pose", "moveId": "crow", "target": 20, "timed": True, "perSide": False, "how": "Hold crow pose for 20 seconds.", "flowCount": 0},
        {"id": "bal-3", "title": "Wall Handstand", "moveId": "wall-hs", "target": 30, "timed": True, "perSide": False, "how": "Hold a wall handstand for 30 seconds.", "flowCount": 0},
        {"id": "bal-4", "title": "Chest-to-Wall Handstand", "moveId": "c2w-hs", "target": 60, "timed": True, "perSide": False, "how": "Hold chest-to-wall for 60 seconds.", "flowCount": 0},
        {"id": "bal-5", "title": "Freestanding Handstand", "moveId": "wall-hs", "target": 5, "timed": True, "perSide": False, "how": "Hold away from the wall for 5 seconds. Log that hold.", "flowCount": 0},
    ]},
    {"id": "flow", "name": "Flow", "summary": "Unlocks from the number of mobility sessions you finish.", "nodes": [
        {"id": "flow-1", "title": "First Flow", "moveId": "cat-cow", "target": 3, "timed": False, "perSide": False, "how": "Finish 3 mobility sessions.", "flowCount": 3},
        {"id": "flow-2", "title": "Ten Flows", "moveId": "wgs", "target": 10, "timed": False, "perSide": False, "how": "Finish 10 mobility sessions.", "flowCount": 10},
        {"id": "flow-3", "title": "Twenty Flows", "moveId": "hip-9090", "target": 20, "timed": False, "perSide": False, "how": "Finish 20 mobility sessions.", "flowCount": 20},
        {"id": "flow-4", "title": "Thirty-five Flows", "moveId": "deep-squat", "target": 35, "timed": False, "perSide": False, "how": "Finish 35 mobility sessions.", "flowCount": 35},
        {"id": "flow-5", "title": "Fifty Flows", "moveId": "child", "target": 50, "timed": False, "perSide": False, "how": "Finish 50 mobility sessions.", "flowCount": 50},
    ]},
]

badges = [
    ("streak-3", "3 day charge", "Count 3 days in a row."),
    ("streak-7", "7 day charge", "Count 7 days in a row."),
    ("streak-14", "14 day charge", "Count 14 days in a row."),
    ("streak-30", "30 day charge", "Count 30 days in a row."),
    ("streak-60", "60 day charge", "Count 60 days in a row."),
    ("streak-100", "100 day charge", "Count 100 days in a row."),
    ("sessions-1", "First session", "Finish 1 session."),
    ("sessions-10", "10 sessions", "Finish 10 sessions."),
    ("sessions-25", "25 sessions", "Finish 25 sessions."),
    ("sessions-50", "50 sessions", "Finish 50 sessions."),
    ("sessions-100", "100 sessions", "Finish 100 sessions."),
    ("sessions-250", "250 sessions", "Finish 250 sessions."),
    ("volume-100", "100 reps", "Log 100 total reps."),
    ("volume-1000", "1000 reps", "Log 1000 total reps."),
    ("volume-5000", "5000 reps", "Log 5000 total reps."),
    ("skill-first", "First node", "Unlock any skill node."),
    ("skill-path", "Path complete", "Finish every node on one path."),
    ("skill-all", "All paths", "Finish every skill path."),
    ("level-5", "Level 5", "Reach level 5."),
    ("level-10", "Level 10", "Reach level 10."),
    ("level-20", "Level 20", "Reach level 20."),
    ("level-30", "Level 30", "Reach level 30."),
    ("variety-10", "10 movements", "Train 10 different movements."),
    ("variety-25", "25 movements", "Train 25 different movements."),
    ("early-bird", "Early session", "Finish a session before 8 in the morning."),
    ("night-owl", "Late session", "Finish a session after 9 at night."),
    ("ghost-1", "Ghost beaten", "Beat your weekly ghost once."),
    ("ghost-5", "Five ghosts", "Beat your weekly ghost five times."),
    ("perfect-week", "Perfect week", "Finish every planned training day in a week."),
    ("pass-saved", "Pass held", "Earn a rest day pass."),
    ("test-1", "First test", "Save one test result."),
    ("test-10", "Ten tests", "Save 10 test results."),
    ("program-1", "Program finished", "Complete one program."),
    ("program-all", "All programs", "Complete all five programs."),
    ("flow-5", "Five flows", "Finish 5 mobility sessions."),
    ("recap-viewed", "Monthly recap", "Open a monthly recap."),
]
assert len(badges) == 36, len(badges)
assert len(moves) >= 56, len(moves)

reminders = [
    "Today's session is ready when you are.",
    "A short session still counts.",
    "The charge stays alive when you train.",
    "Check the three daily quests.",
    "Your ghost is only your own best week.",
    "Rest is planned. Other days ask for a session.",
    "Log the work you already did if it lasted 10 minutes.",
    "Skill tests are waiting when you want them.",
    "Breathe, brace, and start.",
    "The altitude map moves when the work is real.",
    "One more session keeps the week honest.",
    "Mobility counts on a rest day.",
    "Beat yesterday's effort, not a stranger.",
    "The ring fills when the day is counted.",
]

book = {"moves": moves, "programs": programs, "paths": paths, "badges": [{"id": a, "title": b, "detail": c} for a, b, c in badges], "reminders": reminders}
out = os.path.join(os.path.dirname(__file__), "..", "ANTIGRAV", "Code", "Content", "qelv_book.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(book, f)
    f.write("\n")
print("moves", len(moves), "programs", [(p["id"], len(p["days"])) for p in programs], "badges", len(badges))
