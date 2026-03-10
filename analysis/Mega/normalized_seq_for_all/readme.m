🧩 1️⃣ stim1_indSubNorm

Type: Struct array (1 × numSubjects)

Content: Each element corresponds to one subject.

stim1_indSubNorm(subjIdx).data       % channels × time normalized data
stim1_indSubNorm(subjIdx).subjectID  % subject number
stim1_indSubNorm(subjIdx).channels   % channel labels


Computation:
For each subject and each channel,

normData
(
𝑐
ℎ
,
𝑡
)
=
wholeStim
(
𝑐
ℎ
,
𝑡
)
rms(baseline(ch,:))
normData(ch,t)=
rms(baseline(ch,:))
wholeStim(ch,t)
	​


Purpose: Keeps each subject’s normalized EEG data separate, preserving subject identity for further statistical or group-level analysis.

Example use: Compare normalized responses across subjects or compute within-subject variability.

🧩 2️⃣ stim2_indSubNorm

Same as above, but for Stimulus 2 instead of Stimulus 1.

🧩 3️⃣ stim1_mean

Type: Numeric matrix (channels × time)

Computation:
Average of the individually normalized subject data across all subjects:

stim1_mean
(
𝑐
ℎ
,
𝑡
)
=
1
𝑁
∑
𝑠
𝑢
𝑏
𝑗
=
1
𝑁
stim1_indSubNorm(subj).data
(
𝑐
ℎ
,
𝑡
)
stim1_mean(ch,t)=
N
1
	​

subj=1
∑
N
	​

stim1_indSubNorm(subj).data(ch,t)

Purpose: Represents the average normalized response across all subjects, after each subject’s own baseline normalization.

Used in plots: Shown as the red line → “Avg of Individual Normalized”.

🧩 4️⃣ stim2_mean

Same as above, but for Stimulus 2.

🧩 5️⃣ stim1_raw_mean

Type: Numeric matrix (channels × time)

Computation:
Raw whole-stimulus data averaged across subjects without normalization:

stim1_raw_mean
(
𝑐
ℎ
,
𝑡
)
=
1
𝑁
∑
𝑠
𝑢
𝑏
𝑗
=
1
𝑁
wholeStim
𝑠
𝑢
𝑏
𝑗
(
𝑐
ℎ
,
𝑡
)
stim1_raw_mean(ch,t)=
N
1
	​

subj=1
∑
N
	​

wholeStim
subj
	​

(ch,t)

Purpose: Baseline reference for how raw signals look before normalization.

Used in plots: Blue line → “Raw Mean”.

🧩 6️⃣ stim2_raw_mean

Same as above, but for Stimulus 2.

🧩 7️⃣ stim1_global_norm

Type: Numeric matrix (channels × time)

Computation:
Global normalization across all subjects combined — first averaging the baseline and whole-stimulus data across all subjects, then dividing:

stim1_global_norm
(
𝑐
ℎ
,
𝑡
)
=
mean(wholeStim across subj)
rms(mean(baseline across subj))
stim1_global_norm(ch,t)=
rms(mean(baseline across subj))
mean(wholeStim across subj)
	​


Purpose: Represents a single normalization factor per channel computed from the pooled data of all subjects — useful for checking global scaling differences.

Used in plots: Black dashed line → “Global Norm”.

🧩 8️⃣ stim2_global_norm

Same as above, but for Stimulus 2.

📊 Plot Legend Summary
Color / Line	What It Represents	Field Name
🔵 Blue	Raw average (no normalization)	stim1_raw_mean, stim2_raw_mean
🔴 Red	Mean of individually normalized subjects	stim1_mean, stim2_mean
⚫ Black dashed	Global normalization across all subjects	stim1_global_norm, stim2_global_norm
🧠 When to Use Which
Goal	Recommended Field
Look at individual normalized signals per subject	stim1_indSubNorm, stim2_indSubNorm
Compare group-level normalized responses	stim1_mean, stim2_mean
Visualize unnormalized EEG	stim1_raw_mean, stim2_raw_mean
Compare local (subject-specific) vs global scaling	stim1_global_norm, stim2_global_norm