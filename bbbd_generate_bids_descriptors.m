run('config.m');

% Generates participants.tsv, participants.json, dataset_description.json
% and phenotype/ files for each experiment, writing into output_dir.
%
% Run from the data_code/ root after setting paths in config.m.
% data_dir must point to the folder containing experiment_1..experiment_4.

tired_labels = {'VeryAwake', 'Awake', 'Moderate', 'Tired', 'VeryTired'};

%% EXPERIMENTS 1, 2, 3
for experiment_no = 1:3

    demo_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), sprintf('Experiment_%d_demographics.mat', experiment_no)));
    if isempty(demo_file)
        % fallback: find any demographics file
        demo_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), '*demographics*.mat'));
    end
    demo = load(fullfile(demo_file(1).folder, demo_file(1).name));
    demo = demo.(fieldnames(demo){1});

    exp_output = fullfile(output_dir, sprintf('experiment%d', experiment_no));
    make_dir(exp_output);
    phenotype_dir = fullfile(exp_output, 'phenotype');
    make_dir(phenotype_dir);

    %% dataset_description.json
    write_dataset_description(exp_output, experiment_no);

    %% participants.tsv + .json
    use_tired_labels = (experiment_no == 2);
    has_hearing = (experiment_no == 2);
    write_participants(demo, exp_output, tired_labels, use_tired_labels, has_hearing);

    %% phenotype: stimuli_questionnaire_scores.tsv
    points_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), sprintf('Experiment_%d_Points.mat', experiment_no)));
    if isempty(points_file)
        points_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), '*Points*.mat'));
    end
    if ~isempty(points_file)
        pts = load(fullfile(points_file(1).folder, points_file(1).name));
        par_nos = [demo.no];
        if experiment_no == 1
            write_scores_exp1(pts, par_nos, phenotype_dir);
        else
            write_scores_exp23(pts, par_nos, phenotype_dir);
        end
    end

    %% phenotype: feedback, ASRS, digit span (exp2 and 3 only)
    if experiment_no >= 2
        q_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), sprintf('Experiment_%d_questionnaire.mat', experiment_no)));
        if ~isempty(q_file)
            q = load(fullfile(q_file(1).folder, q_file(1).name));
            if isfield(q, 'questionnaireStimulusData')
                write_stimuli_feedback(q.questionnaireStimulusData, [demo.no], phenotype_dir);
            end
        end

        metadata_dir = fullfile(data_dir, sprintf('experiment_%d', experiment_no), 'metadata');
        write_asrs_exp23(experiment_no, fullfile(data_dir, sprintf('experiment_%d', experiment_no)), metadata_dir, phenotype_dir);

        ds_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), sprintf('Experiment_%d_digitspan.mat', experiment_no)));
        if isempty(ds_file)
            % exp3 digitspan may use a different numbering convention
            ds_file = dir(fullfile(data_dir, sprintf('experiment_%d', experiment_no), '*digitspan*.mat'));
        end
        if ~isempty(ds_file)
            ds = load(fullfile(ds_file(1).folder, ds_file(1).name));
            T = ds.(fieldnames(ds){1});
            write_digitspan(T, phenotype_dir);
        end
    end

    fprintf('Experiment %d descriptors written to %s\n', experiment_no, exp_output);
end

%% EXPERIMENTS 4 and 5 (shared raw data, split by doIntervention)
demo_all = load(fullfile(data_dir, 'experiment_4', 'Experiment_6_demographics.mat'));
demo_all = demo_all.(fieldnames(demo_all){1});
pts4 = load(fullfile(data_dir, 'experiment_4', 'Experiment_6_Points.mat'));

di = load(fullfile('config', 'doIntervention_indexing.mat'));
doIntervention = di.doIntervention;

demo_exp4 = demo_all(~doIntervention);  % no intervention
demo_exp5 = demo_all(doIntervention);   % intervention

for exp_no = [4, 5]
    if exp_no == 4
        demo = demo_exp4;
        scores = pts4.Npoints_stim_nointerv;  % 43 x 3
    else
        demo = demo_exp5;
        scores = pts4.Npoints_stim_interv;    % 49 x 3
    end

    exp_output = fullfile(output_dir, sprintf('experiment%d', exp_no));
    make_dir(exp_output);
    phenotype_dir = fullfile(exp_output, 'phenotype');
    make_dir(phenotype_dir);

    write_dataset_description(exp_output, exp_no);
    write_participants(demo, exp_output, tired_labels, true, false);

    par_nos = [demo.no];
    write_scores_exp45(scores, par_nos, phenotype_dir);

    % Feedback (using exp4 raw source)
    q_file = dir(fullfile(data_dir, 'experiment_4', '*questionnaire*.mat'));
    if ~isempty(q_file)
        q = load(fullfile(q_file(1).folder, q_file(1).name));
        if isfield(q, 'questionnaireStimulusData')
            write_stimuli_feedback(q.questionnaireStimulusData, par_nos, phenotype_dir);
        end
    end

    % ASRS (exp4/5 — load from questionnaire.mat)
    write_asrs_exp45(fullfile(data_dir, 'experiment_4', 'Experiment_6_questionnaire.mat'), par_nos, phenotype_dir);

    ds_file = dir(fullfile(data_dir, 'experiment_4', '*digitspan*.mat'));
    if ~isempty(ds_file)
        ds = load(fullfile(ds_file(1).folder, ds_file(1).name));
        T_all = ds.(fieldnames(ds){1});
        mask = ismember(T_all{:,1}, par_nos);
        write_digitspan(T_all(mask,:), phenotype_dir);
    end

    fprintf('Experiment %d descriptors written to %s\n', exp_no, exp_output);
end

%% -----------------------------------------------------------------------

function write_dataset_description(exp_output, experiment_no)
    desc.Name = sprintf('The Brain, Body, and Behaviour Dataset (1.0.0) - Experiment %d', experiment_no);
    desc.BIDSVersion = '1.10.0';
    desc.DatasetType = 'derivative';
    desc.License = 'CC BY 4.0';
    desc.Authors = {'Jens Madsen', 'Nikhil Kuppa', 'Lucas Parra'};
    desc.Acknowledgements = 'We acknowledge the National Science Foundation Grant DRL-1660548 for supporting this project.';
    desc.HowToAcknowledge = 'Cite us';
    desc.Funding = {'DRL-2201835'};
    desc.EthicsApprovals = {'The City University of New York (CUNY) University Integrated Institutional Review Board'};
    desc.GeneratedBy = struct('Name', 'Manual', 'Description', ...
        'MATLAB: Converted .mat files to .bdf files for EEG recordings, and .mat files to tsv.gz files for physiological and eyetracking recordings (eg: ECG, gaze etc)');

    write_json(fullfile(exp_output, 'dataset_description.json'), desc);
end

function write_participants(demo, exp_output, tired_labels, use_tired_labels, has_hearing)
    n = length(demo);

    participant_id = cell(n, 1);
    species        = repmat({'homosapiens'}, n, 1);
    Sex            = cell(n, 1);
    Age            = zeros(n, 1);
    Occupation     = cell(n, 1);
    Tired          = cell(n, 1);
    Study_time     = zeros(n, 1);
    GPA            = zeros(n, 1);
    Caffeine       = zeros(n, 1);
    Occupation_field = cell(n, 1);
    if has_hearing
        Hearing = repmat({'Yes'}, n, 1);
    end

    for i = 1:n
        participant_id{i} = sprintf('sub-%02d', demo(i).no);
        Sex{i}            = demo(i).Sex;
        Age(i)            = demo(i).Age;
        Occupation{i}     = demo(i).Occupation;
        Study_time(i)     = demo(i).Study_time;
        GPA(i)            = demo(i).GPA;
        Caffeine(i)       = demo(i).Caffeine;
        Occupation_field{i} = demo(i).Occupation_field;

        t = demo(i).Tired;
        if use_tired_labels
            if isnumeric(t) && t >= 1 && t <= 5
                Tired{i} = tired_labels{t};
            else
                Tired{i} = char(t);
            end
        else
            if isnumeric(t)
                Tired{i} = num2str(t);
            else
                Tired{i} = char(t);
            end
        end
    end

    % Build table
    if has_hearing
        T = table(participant_id, species, Sex, Age, Occupation, Tired, Hearing, ...
            Study_time, GPA, Caffeine, Occupation_field);
    else
        T = table(participant_id, species, Sex, Age, Occupation, Tired, ...
            Study_time, GPA, Caffeine, Occupation_field);
    end

    writetable(T, fullfile(exp_output, 'participants.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t', 'WriteVariableNames', true);

    % participants.json sidecar
    sidecar.participant_id.Description = 'unique identifier for the participant';
    sidecar.species.Description = 'species of the participant';
    sidecar.species.Levels.homosapiens = 'human';
    sidecar.Sex.Description = 'sex of the participant as reported by the participant';
    sidecar.Sex.Levels.Male = 'male';
    sidecar.Sex.Levels.Female = 'female';
    sidecar.Age.Description = 'age of the participant';
    sidecar.Age.Units = 'years';
    sidecar.Occupation.Description = 'occupation of the participant';
    sidecar.Tired.Description = 'current state of tiredness of the participant';
    sidecar.Tired.Levels.VeryAwake = 'not tired at all';
    sidecar.Tired.Levels.Awake = 'feeling awake';
    sidecar.Tired.Levels.Moderate = 'moderate level of tiredness';
    sidecar.Tired.Levels.Tired = 'feeling tired';
    sidecar.Tired.Levels.VeryTired = 'extremely tired';
    if has_hearing
        sidecar.Hearing.Description = 'hearing status of the participant';
        sidecar.Hearing.Levels.Yes = 'hearing';
        sidecar.Hearing.Levels.No = 'not hearing';
    end
    sidecar.Study_time.Description = 'number of hours the participant studied';
    sidecar.Study_time.Units = 'hours';
    sidecar.GPA.Description = 'Grade Point Average of the participant';
    sidecar.Caffeine.Description = 'Time since last caffeine consumption of the participant';
    sidecar.Caffeine.Units = 'Hours';
    sidecar.Occupation_field.Description = 'field of occupation of the participant';

    write_json(fullfile(exp_output, 'participants.json'), sidecar);
end

function write_scores_exp1(pts, par_nos, phenotype_dir)
    % Exp1: pre (domain) and post (memory) scores, 27 subs x 5 stims
    rows = {};
    for i = 1:length(par_nos)
        for s = 1:size(pts.Npoints_stim_post, 2)
            rows{end+1} = {sprintf('sub-%02d', par_nos(i)), s, ...
                NaN, pts.Npoints_stim_pre(i, s), ...
                NaN, pts.Npoints_stim_post(i, s)};
        end
    end
    T = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'participant_id','stimulus_id','total_domain_questions','domain_score', ...
         'total_memory_questions','memory_score'});
    writetable(T, fullfile(phenotype_dir, 'stimuli_questionnaire_scores.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');
end

function write_scores_exp23(pts, par_nos, phenotype_dir)
    % Exp2/3: single score per stim, subs x stims
    scores = pts.Npoints_stim;
    rows = {};
    for i = 1:length(par_nos)
        for s = 1:size(scores, 2)
            rows{end+1} = {sprintf('sub-%02d', par_nos(i)), s, NaN, scores(i, s)};
        end
    end
    T = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'participant_id','stim_no','total_questions','score'});
    writetable(T, fullfile(phenotype_dir, 'stimuli_questionnaire_scores.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');
end

function write_scores_exp45(scores, par_nos, phenotype_dir)
    % Exp4/5: single score per stim, subs x 3 stims
    rows = {};
    for i = 1:length(par_nos)
        for s = 1:size(scores, 2)
            rows{end+1} = {sprintf('sub-%02d', par_nos(i)), s, NaN, scores(i, s)};
        end
    end
    T = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'participant_id','stimulus_no','total_questions','score'});
    writetable(T, fullfile(phenotype_dir, 'stimuli_questionnaire_scores.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');
end

function write_stimuli_feedback(stimData, par_nos, phenotype_dir)
    % questionnaireStimulusData: 1 x Nstim struct, each has engaging/educational/enjoyable [Nsub x 1]
    rows = {};
    n_stim = length(stimData);
    for s = 1:n_stim
        engaging    = stimData(s).engaging;
        enjoyable   = stimData(s).enjoyable;
        educational = stimData(s).educational;
        for i = 1:length(par_nos)
            rows{end+1} = {sprintf('sub-%02d', par_nos(i)), sprintf('Stim-%02d', s), ...
                engaging(i), enjoyable(i), educational(i)};
        end
    end
    T = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'participant_id','stimulus','engaging','enjoyable','educational'});
    writetable(T, fullfile(phenotype_dir, 'stimuli_feedback_meta.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');

    sidecar.participant_id.Description = 'unique participant identifier';
    sidecar.stimulus.Description = 'stimulus identifier';
    sidecar.engaging.Description = 'self-reported engagement rating for the stimulus';
    sidecar.enjoyable.Description = 'self-reported enjoyability rating for the stimulus';
    sidecar.educational.Description = 'self-reported educational value rating for the stimulus';
    write_json(fullfile(phenotype_dir, 'stimuli_feedback_meta.json'), sidecar);
end

% -------------------------------------------------------------------------
% ASRS functions
% -------------------------------------------------------------------------

function write_asrs_exp23(experiment_no, data_dir_exp, metadata_dir, phenotype_dir)
    % Exp2: per-question ASRS from questionnaireParticipantData in questionnaire.mat,
    %       mapped to participant_nos via metadata file alphabetical order.
    % Exp3: falls back to per-participant swan_questions embedded in metadata files.
    q_file = fullfile(data_dir_exp, sprintf('Experiment_%d_questionnaire.mat', experiment_no));
    if isfile(q_file)
        q = load(q_file);
        if isfield(q, 'questionnaireParticipantData')
            write_asrs_from_questionnaire(q.questionnaireParticipantData, metadata_dir, phenotype_dir);
            return;
        end
    end
    % Fall back: ASRS data is embedded in each metadata file (exp3 pattern)
    write_asrs_from_metadata(metadata_dir, phenotype_dir);
end

function write_asrs_from_questionnaire(questions, metadata_dir, phenotype_dir)
    % Load participant_nos from metadata files in alphabetical (dir) order
    meta_files = dir(fullfile(metadata_dir, '*.mat'));
    n_meta = length(meta_files);
    par_nos_by_meta = zeros(1, n_meta);
    for k = 1:n_meta
        m = load(fullfile(meta_files(k).folder, meta_files(k).name));
        par_nos_by_meta(k) = get_par_no_from_metadata(m);
    end

    asrs_raw = [];       % N x 18, 1-5 scale
    valid_par_nos = [];

    n_q = min(length(questions), n_meta);
    for i = 1:n_q
        resp = questions{1,i}.swanData.responses;
        if any(isnan(resp(:)))
            continue;
        end
        asrs_raw = vertcat(asrs_raw, double(resp(:)'));
        valid_par_nos = [valid_par_nos, par_nos_by_meta(i)];
    end

    write_asrs_from_raw(asrs_raw, valid_par_nos, phenotype_dir);
end

function write_asrs_from_metadata(metadata_dir, phenotype_dir)
    % Exp3 pattern: ASRS data embedded in each metadata file as swan_questions
    meta_files = dir(fullfile(metadata_dir, '*.mat'));

    asrs_raw = [];
    par_nos  = [];

    for k = 1:length(meta_files)
        m = load(fullfile(meta_files(k).folder, meta_files(k).name));
        md = m.results;

        par_no = md.demographic.participant_no;

        part1 = extract_swan_answers([md.swan_questions{1,1}.item{:,:}]);
        part2 = extract_swan_answers([md.swan_questions{1,2}.item{:,:}]);
        answers = [part1, part2];  % 1 x 18, 1-5 scale

        asrs_raw = vertcat(asrs_raw, answers);
        par_nos  = [par_nos, par_no];
    end

    write_asrs_from_raw(asrs_raw, par_nos, phenotype_dir);
end

function answers = extract_swan_answers(items)
    % items: struct array with fields .question_no and .answer_no
    % Returns a row vector of answer values sorted by question_no.
    q_nos = [items.question_no];
    a_nos = [items.answer_no];
    [~, idx] = sort(q_nos);
    answers = a_nos(idx);
end

function par_no = get_par_no_from_metadata(m)
    % Handles multiple metadata field layouts across experiments
    if isfield(m, 'metadata') && isfield(m.metadata, 'participant_no')
        par_no = m.metadata.participant_no;
    elseif isfield(m, 'results') && isfield(m.results, 'demographic')
        par_no = m.results.demographic.participant_no;
    else
        fields = fieldnames(m);
        md = m.(fields{1});
        if isfield(md, 'participant_no')
            par_no = md.participant_no;
        else
            error('Cannot find participant_no in metadata file');
        end
    end
end

function write_asrs_exp45(questionnaire_file, par_nos, phenotype_dir)
    % Exp4/5: load ASRS from questionnaire.mat. Writes per-question data if
    % available (q1-q18 columns present), otherwise writes summary scores only.
    if ~isfile(questionnaire_file)
        fprintf('ASRS: questionnaire file not found: %s\n', questionnaire_file);
        return;
    end
    q = load(questionnaire_file);

    % Find the ASRS table (try common field names)
    T_all = [];
    for fname = fieldnames(q)'
        f = fname{1};
        if contains(lower(f), 'asrs')
            T_all = q.(f);
            break;
        end
    end
    if isempty(T_all)
        fprintf('ASRS: no ASRS field found in %s\n', questionnaire_file);
        return;
    end

    % Filter to this experiment's participants
    if istable(T_all) && any(strcmp(T_all.Properties.VariableNames, 'participant_no'))
        mask = ismember(T_all.participant_no, par_nos);
        T = T_all(mask, :);
    else
        T = T_all;
    end

    % Rename mevd-style column names to BBBD-style
    T = remap_asrs_columns(T);

    % Check if per-question columns exist
    has_per_question = any(strcmp(T.Properties.VariableNames, 'q1'));

    participant_id = arrayfun(@(x) sprintf('sub-%02d', x), T.participant_no, 'UniformOutput', false);
    T2 = removevars(T, 'participant_no');
    T2 = addvars(T2, participant_id, 'Before', 1, 'NewVariableNames', 'participant_id');

    writetable(T2, fullfile(phenotype_dir, 'asrs_questionnaire.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');
    write_asrs_sidecar_json(phenotype_dir, has_per_question);
end

function T = remap_asrs_columns(T)
    % Rename mevd-style column names to BBBD-style column names
    col_map = {
        'scale4_screener',       'dichotomous_screener_score';
        'scale4_fulltest',       'dichotomous_full_score';
        'scale24_screener',      'likert_screener_score';
        'scale24_fulltest',      'likert_full_score';
        'hyperactivity_score',   'hyperactivity_subscore';
        'inattentive_score',     'inattention_subscore';
        'inattentive',           'inattention_subscore';
        'hyperactive',           'hyperactivity_subscore';
        'screen_test_score',     'dichotomous_screener_score';
        'full_test_score',       'dichotomous_full_score';
        'scale_24_screen_score', 'likert_screener_score';
        'scale_24_full_score',   'likert_full_score';
    };
    for k = 1:size(col_map, 1)
        old_name = col_map{k,1};
        new_name = col_map{k,2};
        idx = strcmp(T.Properties.VariableNames, old_name);
        if any(idx) && ~any(strcmp(T.Properties.VariableNames, new_name))
            T.Properties.VariableNames{idx} = new_name;
        end
    end
end

function write_asrs_from_raw(asrs_raw, par_nos, phenotype_dir)
    % asrs_raw: N x 18 matrix of 1-5 scale values
    % par_nos:  1 x N participant numbers
    % Converts to 0-4 for storage, computes and appends all score columns.

    asrs_04 = asrs_raw - 1;  % 0-4 scale for TSV storage
    scores  = compute_asrs_scores(asrs_raw);

    q_names     = arrayfun(@(x) sprintf('q%d', x), 1:18, 'UniformOutput', false);
    score_names = {'dichotomous_screener_score','dichotomous_full_score', ...
                   'likert_screener_score','likert_full_score', ...
                   'hyperactivity_subscore','inattention_subscore'};

    participant_id = arrayfun(@(x) sprintf('sub-%02d', x), par_nos(:), 'UniformOutput', false);

    T = array2table([asrs_04, scores], 'VariableNames', [q_names, score_names]);
    T = addvars(T, participant_id, 'Before', 1, 'NewVariableNames', 'participant_id');

    writetable(T, fullfile(phenotype_dir, 'asrs_questionnaire.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');

    write_asrs_sidecar_json(phenotype_dir, true);
end

function scores = compute_asrs_scores(asrs_raw)
    % Input:  N x 18 matrix of 1-5 scale values
    % Output: N x 6 [dichotomous_screener, dichotomous_full,
    %                likert_screener, likert_full,
    %                hyperactivity_subscore, inattention_subscore]
    %
    % Likert scores use 0-4 scale (= raw - 1).
    % Hyperactivity/inattention subscores use raw 1-5 scale.

    asrs_04 = asrs_raw - 1;

    likert_screener = sum(asrs_04(:, 1:6), 2);
    likert_full     = sum(asrs_04, 2);

    % high-frequency items: endorsed at >= 3 (1-5 scale) = >= 2 (0-4 scale)
    % low-frequency items:  endorsed at >= 4 (1-5 scale) = >= 3 (0-4 scale)
    columns_high = [1,2,3,9,12,16,18];
    columns_low  = [4,5,6,7,8,10,11,13,14,15,17];
    high_screener = intersect(columns_high, 1:6);  % [1,2,3]
    low_screener  = intersect(columns_low,  1:6);  % [4,5,6]

    dichotomous_full     = sum(asrs_04(:, columns_high) >= 2, 2) + ...
                           sum(asrs_04(:, columns_low)  >= 3, 2);
    dichotomous_screener = sum(asrs_04(:, high_screener) >= 2, 2) + ...
                           sum(asrs_04(:, low_screener)  >= 3, 2);

    columns_inattentive  = [1,2,3,4,7,8,9,10,11,12];
    columns_hyperactive  = [5,6,13,14,15,16,17,18];
    inattention_subscore   = sum(asrs_raw(:, columns_inattentive), 2);
    hyperactivity_subscore = sum(asrs_raw(:, columns_hyperactive), 2);

    scores = [dichotomous_screener, dichotomous_full, likert_screener, likert_full, ...
              hyperactivity_subscore, inattention_subscore];
end

function write_asrs_sidecar_json(phenotype_dir, include_per_question)
    sidecar.participant_id.Description = 'unique participant identifier';
    if include_per_question
        for qi = 1:18
            key = sprintf('q%d', qi);
            sidecar.(key).Description = sprintf('ASRS question %d response', qi);
            sidecar.(key).Levels.x0 = 'Never';
            sidecar.(key).Levels.x1 = 'Rarely';
            sidecar.(key).Levels.x2 = 'Sometimes';
            sidecar.(key).Levels.x3 = 'Often';
            sidecar.(key).Levels.x4 = 'Very Often';
        end
    end
    sidecar.dichotomous_screener_score.Description = 'ASRS dichotomous screener score (Part A, 6 questions)';
    sidecar.dichotomous_full_score.Description     = 'ASRS dichotomous full score (all 18 questions)';
    sidecar.likert_screener_score.Description      = 'ASRS Likert screener score (Part A, 6 questions, 0-4 scale)';
    sidecar.likert_full_score.Description          = 'ASRS Likert full score (all 18 questions, 0-4 scale)';
    sidecar.hyperactivity_subscore.Description     = 'ASRS hyperactivity/impulsivity subscore (raw 1-5 scale sum)';
    sidecar.inattention_subscore.Description       = 'ASRS inattention subscore (raw 1-5 scale sum)';
    write_json(fullfile(phenotype_dir, 'asrs_questionnaire.json'), sidecar);
end

% -------------------------------------------------------------------------

function write_digitspan(T, phenotype_dir)
    % T: table with columns [participant_no, score, weighted_score]
    cols = T.Properties.VariableNames;
    participant_id = arrayfun(@(x) sprintf('sub-%02d', x), T.(cols{1}), 'UniformOutput', false);
    T2 = table(participant_id, T.(cols{2}), T.(cols{3}), ...
        'VariableNames', {'participant_id', 'score', 'weighted_score'});
    writetable(T2, fullfile(phenotype_dir, 'digit_span_scores.tsv'), ...
        'FileType', 'text', 'Delimiter', '\t');

    sidecar.participant_id.Description = 'unique participant identifier';
    sidecar.score.Description = 'digit span forward score';
    sidecar.weighted_score.Description = 'weighted digit span score';
    write_json(fullfile(phenotype_dir, 'digit_span_scores.json'), sidecar);
end

function write_json(filepath, s)
    fid = fopen(filepath, 'w');
    if fid == -1
        error('Cannot create file: %s', filepath);
    end
    fprintf(fid, '%s', jsonencode(s, 'PrettyPrint', true));
    fclose(fid);
end

function make_dir(d)
    if ~exist(d, 'dir')
        mkdir(d);
    end
end
