import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pte_mobile/models/cv/certification.dart';
import 'package:pte_mobile/models/cv/cv.dart';
import 'package:pte_mobile/models/cv/education.dart';
import 'package:pte_mobile/models/cv/experience.dart';
import 'package:pte_mobile/models/cv/language.dart';
import 'package:pte_mobile/models/cv/project.dart';
import 'package:pte_mobile/models/cv/skill.dart';
import 'package:pte_mobile/models/identifiable.dart';
import 'package:pte_mobile/services/cv_service.dart';
import 'package:intl/intl.dart';

// Define a class to hold the updated data for returning
class UpdatedCVData {
  final Cv cv;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Certification> certifications;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Project> projects;

  UpdatedCVData({
    required this.cv,
    required this.educations,
    required this.experiences,
    required this.certifications,
    required this.skills,
    required this.languages,
    required this.projects,
  });
}

class UpdateResumeScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Cv cv;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Certification> certifications;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Project> projects;

  const UpdateResumeScreen({
    Key? key,
    required this.userId,
    required this.token,
    required this.cv,
    required this.educations,
    required this.experiences,
    required this.certifications,
    required this.skills,
    required this.languages,
    required this.projects,
  }) : super(key: key);

  @override
  _UpdateResumeScreenState createState() => _UpdateResumeScreenState();
}

class _UpdateResumeScreenState extends State<UpdateResumeScreen> {
  late TextEditingController _summaryController;
  final _formKey = GlobalKey<FormState>();
  final CvService _cvService = CvService();
  late Cv _cv;
  late List<Education> _educations;
  late List<Experience> _experiences;
  late List<Certification> _certifications;
  late List<Skill> _skills;
  late List<Language> _languages;
  late List<Project> _projects;
  String? _error;
  bool _isLoading = false;

  Map<String, String?> _editingItemId = {
    'Education': null,
    'Experience': null,
    'Certification': null,
    'Skill': null,
    'Language': null,
    'Project': null,
  };

  Map<String, bool> _addingNewItem = {
    'Education': false,
    'Experience': false,
    'Certification': false,
    'Skill': false,
    'Language': false,
    'Project': false,
  };

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: initState called');
    _summaryController = TextEditingController(text: widget.cv.summary);
    debugPrint('DEBUG: _summaryController initialized with text: ${widget.cv.summary}');
    _cv = widget.cv;
    _educations = List.from(widget.educations);
    _experiences = List.from(widget.experiences);
    _certifications = List.from(widget.certifications);
    _skills = List.from(widget.skills);
    _languages = List.from(widget.languages);
    _projects = List.from(widget.projects);
    debugPrint('DEBUG: Initial state - educations: ${_educations.length}, experiences: ${_experiences.length}, certifications: ${_certifications.length}, skills: ${_skills.length}, languages: ${_languages.length}, projects: ${_projects.length}');
  }

  @override
  void dispose() {
    debugPrint('DEBUG: dispose called');
    _summaryController.dispose();
    debugPrint('DEBUG: _summaryController disposed');
    super.dispose();
  }

  bool _validateForm(dynamic item) {
    debugPrint('DEBUG: _validateForm called with item: $item');
    if (item is Education && (item.establishment.isEmpty || item.diploma.isEmpty)) {
      debugPrint('DEBUG: Validation failed: Establishment or Diploma is empty');
      _showErrorSnackBar('Institution and Degree are required');
      return false;
    }
    if (item is Experience && (item.company.isEmpty || item.job.isEmpty)) {
      debugPrint('DEBUG: Validation failed: Company or Job is empty');
      _showErrorSnackBar('Company and Job Title are required');
      return false;
    }
    if (item is Certification && (item.domaine.isEmpty || item.credential.isEmpty)) {
      debugPrint('DEBUG: Validation failed: Domaine or Credential is empty');
      _showErrorSnackBar('Domain and Certification Name are required');
      return false;
    }
    if (item is Skill && item.name.isEmpty) {
      debugPrint('DEBUG: Validation failed: Skill Name is empty');
      _showErrorSnackBar('Skill Name is required');
      return false;
    }
    if (item is Language && item.name.isEmpty) {
      debugPrint('DEBUG: Validation failed: Language Name is empty');
      _showErrorSnackBar('Language Name is required');
      return false;
    }
    if (item is Project && (item.organization.isEmpty || item.title.isEmpty)) {
      debugPrint('DEBUG: Validation failed: Organization or Title is empty');
      _showErrorSnackBar('Organization and Project Title are required');
      return false;
    }
    debugPrint('DEBUG: Validation passed for item: $item');
    return true;
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _updateItem<T extends Identifiable>(
    T item,
    String type,
    Future<void> Function(String, T, String) updateFunction,
    Future<List<T>> Function(String, String) fetchFunction,
  ) async {
    if (_validateForm(item)) {
      setState(() => _isLoading = true);
      debugPrint('DEBUG: _isLoading set to true');
      try {
        debugPrint('DEBUG: Calling updateFunction for $type');
        await updateFunction(item.id, item, widget.token);
        debugPrint('DEBUG: Fetching updated list for $type');
        final updatedList = await fetchFunction(widget.cv.id, widget.token);
        setState(() {
          if (type == 'Education') _educations = updatedList as List<Education>;
          if (type == 'Experience') _experiences = updatedList as List<Experience>;
          if (type == 'Certification') _certifications = updatedList as List<Certification>;
          if (type == 'Skill') _skills = updatedList as List<Skill>;
          if (type == 'Language') _languages = updatedList as List<Language>;
          if (type == 'Project') _projects = updatedList as List<Project>;
          _editingItemId[type] = null;
          _error = null;
          debugPrint('DEBUG: $type updated, list updated, _editingItemId reset, _error cleared');
        });
        _showSuccessSnackBar('$type updated successfully');
      } catch (e) {
        setState(() {
          _error = e.toString();
          debugPrint('DEBUG: Error occurred in $type update: $_error');
        });
        _showErrorSnackBar('Error updating $type: $e');
      } finally {
        setState(() {
          _isLoading = false;
          debugPrint('DEBUG: _isLoading set to false');
        });
      }
    }
  }

  Future<void> _addItem<T extends Identifiable>(
    T item,
    String type,
    Future<void> Function(T, String) addFunction,
    Future<List<T>> Function(String, String) fetchFunction,
  ) async {
    if (_validateForm(item)) {
      setState(() => _isLoading = true);
      debugPrint('DEBUG: _isLoading set to true');
      try {
        debugPrint('DEBUG: Calling addFunction for $type');
        await addFunction(item, widget.token);
        debugPrint('DEBUG: Fetching updated list for $type');
        final updatedList = await fetchFunction(widget.cv.id, widget.token);
        setState(() {
          if (type == 'Education') _educations = updatedList as List<Education>;
          if (type == 'Experience') _experiences = updatedList as List<Experience>;
          if (type == 'Certification') _certifications = updatedList as List<Certification>;
          if (type == 'Skill') _skills = updatedList as List<Skill>;
          if (type == 'Language') _languages = updatedList as List<Language>;
          if (type == 'Project') _projects = updatedList as List<Project>;
          _addingNewItem[type] = false;
          _error = null;
          debugPrint('DEBUG: $type added, list updated, _addingNewItem reset, _error cleared');
        });
        _showSuccessSnackBar('$type added successfully');
      } catch (e) {
        setState(() {
          _error = e.toString();
          debugPrint('DEBUG: Error occurred in $type add: $_error');
        });
        _showErrorSnackBar('Error adding $type: $e');
      } finally {
        setState(() {
          _isLoading = false;
          debugPrint('DEBUG: _isLoading set to false');
        });
      }
    }
  }

  Future<void> _deleteItem<T extends Identifiable>(
    String id,
    String type,
    Future<void> Function(String, String) deleteFunction,
    Future<List<T>> Function(String, String) fetchFunction,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $type', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to delete this $type? This action cannot be undone.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      debugPrint('DEBUG: _isLoading set to true');
      try {
        debugPrint('DEBUG: Calling deleteFunction for $type, ID: $id');
        await deleteFunction(id, widget.token);
        debugPrint('DEBUG: Fetching updated list for $type');
        final updatedList = await fetchFunction(widget.cv.id, widget.token);
        setState(() {
          if (type == 'Education') _educations = updatedList as List<Education>;
          if (type == 'Experience') _experiences = updatedList as List<Experience>;
          if (type == 'Certification') _certifications = updatedList as List<Certification>;
          if (type == 'Skill') _skills = updatedList as List<Skill>;
          if (type == 'Language') _languages = updatedList as List<Language>;
          if (type == 'Project') _projects = updatedList as List<Project>;
          _error = null;
          debugPrint('DEBUG: $type deleted, list updated, _error cleared');
        });
        _showSuccessSnackBar('$type deleted successfully');
      } catch (e) {
        setState(() {
          _error = e.toString();
          debugPrint('DEBUG: Error occurred in $type delete: $_error');
        });
        _showErrorSnackBar('Error deleting $type: $e');
      } finally {
        setState(() {
          _isLoading = false;
          debugPrint('DEBUG: _isLoading set to false');
        });
      }
    }
  }

  T _createNewItem<T extends Identifiable>(String type) {
    if (type == 'Education') {
      return Education(
        id: '',
        cvId: widget.cv.id,
        establishment: '',
        section: '',
        diploma: '',
        yearStart: DateTime.now(),
        present: false,
      ) as T;
    } else if (type == 'Experience') {
      return Experience(
        id: '',
        cvId: widget.cv.id,
        company: '',
        job: '',
        taskDescription: '',
        start: DateTime.now(),
        present: false,
      ) as T;
    } else if (type == 'Certification') {
      return Certification(
        id: '',
        cvId: widget.cv.id,
        domaine: '',
        credential: '',
        date: DateTime.now(),
      ) as T;
    } else if (type == 'Skill') {
      return Skill(
        id: '',
        cvId: widget.cv.id,
        name: '',
        level: 0,
      ) as T;
    } else if (type == 'Language') {
      return Language(
        id: '',
        cvId: widget.cv.id,
        name: '',
        level: 0,
      ) as T;
    } else {
      return Project(
        id: '',
        cvId: widget.cv.id,
        organization: '',
        title: '',
        description: '',
        date: DateTime.now(),
      ) as T;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    debugPrint('DEBUG: build called, _isLoading: $_isLoading, _error: $_error');
    
    return Scaffold(
      backgroundColor: colorScheme.background,
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.chevron_left, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    'Edit Resume',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  centerTitle: true,
  backgroundColor: Theme.of(context).colorScheme.primary,
  actions: [
    Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading
            ? null
            : () async {
                debugPrint('DEBUG: Save button pressed, summary: ${_summaryController.text}');
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  debugPrint('DEBUG: _isLoading set to true');
                  try {
                    debugPrint('DEBUG: Calling updateSummary with cvId: ${widget.cv.id}, userId: ${widget.userId}');
                    await _cvService.updateSummary(widget.cv.id, _summaryController.text, widget.userId, widget.token);
                    _cv = Cv(
                      id: widget.cv.id,
                      userId: widget.userId,
                      summary: _summaryController.text,
                      educationIds: _educations.map((e) => e.id).toList(),
                      experienceIds: _experiences.map((e) => e.id).toList(),
                      certificationIds: _certifications.map((c) => c.id).toList(),
                      projectIds: _projects.map((p) => p.id).toList(),
                      skillIds: _skills.map((s) => s.id).toList(),
                      languageIds: _languages.map((l) => l.id).toList(),
                    );
                    setState(() {
                      _error = null;
                      debugPrint('DEBUG: _error cleared');
                    });
                    Navigator.pop(
                      context,
                      UpdatedCVData(
                        cv: _cv,
                        educations: _educations,
                        experiences: _experiences,
                        certifications: _certifications,
                        skills: _skills,
                        languages: _languages,
                        projects: _projects,
                      ),
                    );
                    debugPrint('DEBUG: Navigating back with updated data');
                    _showSuccessSnackBar('Resume updated successfully');
                  } catch (e) {
                    setState(() {
                      _error = e.toString();
                      debugPrint('DEBUG: Error occurred in summary update: $_error');
                    });
                    _showErrorSnackBar('Error updating resume: $e');
                  } finally {
                    setState(() {
                      _isLoading = false;
                      debugPrint('DEBUG: _isLoading set to false');
                    });
                  }
                } else {
                  debugPrint('DEBUG: Form validation failed');
                }
              },
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            : Icon(Icons.save_outlined, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(_isLoading ? 'Saving...' : 'Save'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
  ],
),
      body: _error != null
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _error = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(isTablet ? 24 : 16),
                child: Form(
                  key: _formKey,
                  child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
                ),
              ),
            ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSummarySection(),
        const SizedBox(height: 16),
        _buildSection<Education>(
          'Education',
          _educations,
          'Education',
          Icons.school_outlined,
          Theme.of(context).colorScheme.primary,
          (edu) => _buildEducationItem(edu),
          (edu, updateCallback) => _buildEducationForm(edu, updateCallback),
          _cvService.updateEducation,
          _cvService.getEducation,
          _cvService.addEducation,
          _cvService.deleteEducation,
        ),
        const SizedBox(height: 16),
        _buildSection<Experience>(
          'Experience',
          _experiences,
          'Experience',
          Icons.work_outline,
          Theme.of(context).colorScheme.secondary,
          (exp) => _buildExperienceItem(exp),
          (exp, updateCallback) => _buildExperienceForm(exp, updateCallback),
          _cvService.updateExperience,
          _cvService.getExperience,
          _cvService.addExperience,
          _cvService.deleteExperience,
        ),
        const SizedBox(height: 16),
        _buildSection<Certification>(
          'Certifications',
          _certifications,
          'Certification',
          Icons.verified_outlined,
          Theme.of(context).colorScheme.secondary,
          (cert) => _buildCertificationItem(cert),
          (cert, updateCallback) => _buildCertificationForm(cert, updateCallback),
          _cvService.updateCertification,
          _cvService.getCertifications,
          _cvService.addCertification,
          _cvService.deleteCertification,
        ),
        const SizedBox(height: 16),
        _buildSection<Skill>(
          'Skills',
          _skills,
          'Skill',
          Icons.star_outline,
          Theme.of(context).colorScheme.secondary,
          (skill) => _buildSkillItem(skill),
          (skill, updateCallback) => _buildSkillForm(skill, updateCallback),
          _cvService.updateSkill,
          _cvService.getSkills,
          _cvService.addSkill,
          _cvService.deleteSkill,
        ),
        const SizedBox(height: 16),
        _buildSection<Language>(
          'Languages',
          _languages,
          'Language',
          Icons.language_outlined,
          Theme.of(context).colorScheme.primary,
          (lang) => _buildLanguageItem(lang),
          (lang, updateCallback) => _buildLanguageForm(lang, updateCallback),
          _cvService.updateLanguage,
          _cvService.getLanguages,
          _cvService.addLanguage,
          _cvService.deleteLanguage,
        ),
        const SizedBox(height: 16),
        _buildSection<Project>(
          'Projects',
          _projects,
          'Project',
          Icons.folder_outlined,
          Theme.of(context).colorScheme.primary,
          (proj) => _buildProjectItem(proj),
          (proj, updateCallback) => _buildProjectForm(proj, updateCallback),
          _cvService.updateProject,
          _cvService.getProjects,
          _cvService.addProject,
          _cvService.deleteProject,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildSummarySection(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildSection<Education>(
                    'Education',
                    _educations,
                    'Education',
                    Icons.school_outlined,
                    Theme.of(context).colorScheme.primary,
                    (edu) => _buildEducationItem(edu),
                    (edu, updateCallback) => _buildEducationForm(edu, updateCallback),
                    _cvService.updateEducation,
                    _cvService.getEducation,
                    _cvService.addEducation,
                    _cvService.deleteEducation,
                  ),
                  const SizedBox(height: 16),
                  _buildSection<Certification>(
                    'Certifications',
                    _certifications,
                    'Certification',
                    Icons.verified_outlined,
                    Theme.of(context).colorScheme.secondary,
                    (cert) => _buildCertificationItem(cert),
                    (cert, updateCallback) => _buildCertificationForm(cert, updateCallback),
                    _cvService.updateCertification,
                    _cvService.getCertifications,
                    _cvService.addCertification,
                    _cvService.deleteCertification,
                  ),
                  const SizedBox(height: 16),
                  _buildSection<Language>(
                    'Languages',
                    _languages,
                    'Language',
                    Icons.language_outlined,
                    Theme.of(context).colorScheme.primary,
                    (lang) => _buildLanguageItem(lang),
                    (lang, updateCallback) => _buildLanguageForm(lang, updateCallback),
                    _cvService.updateLanguage,
                    _cvService.getLanguages,
                    _cvService.addLanguage,
                    _cvService.deleteLanguage,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildSection<Experience>(
                    'Experience',
                    _experiences,
                    'Experience',
                    Icons.work_outline,
                    Theme.of(context).colorScheme.secondary,
                    (exp) => _buildExperienceItem(exp),
                    (exp, updateCallback) => _buildExperienceForm(exp, updateCallback),
                    _cvService.updateExperience,
                    _cvService.getExperience,
                    _cvService.addExperience,
                    _cvService.deleteExperience,
                  ),
                  const SizedBox(height: 16),
                  _buildSection<Skill>(
                    'Skills',
                    _skills,
                    'Skill',
                    Icons.star_outline,
                    Theme.of(context).colorScheme.secondary,
                    (skill) => _buildSkillItem(skill),
                    (skill, updateCallback) => _buildSkillForm(skill, updateCallback),
                    _cvService.updateSkill,
                    _cvService.getSkills,
                    _cvService.addSkill,
                    _cvService.deleteSkill,
                  ),
                  const SizedBox(height: 16),
                  _buildSection<Project>(
                    'Projects',
                    _projects,
                    'Project',
                    Icons.folder_outlined,
                    Theme.of(context).colorScheme.primary,
                    (proj) => _buildProjectItem(proj),
                    (proj, updateCallback) => _buildProjectForm(proj, updateCallback),
                    _cvService.updateProject,
                    _cvService.getProjects,
                    _cvService.addProject,
                    _cvService.deleteProject,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummarySection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Professional Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Write a brief summary of your professional background and key achievements.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _summaryController,
            maxLines: 6,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Summary',
              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              hintText: 'Enter your professional summary here...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.error),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              debugPrint('DEBUG: Validating summary field, value: $value');
              if (value!.isEmpty) {
                debugPrint('DEBUG: Summary validation failed: empty');
                return 'Summary is required';
              }
              return null;
            },
            autofocus: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSection<T extends Identifiable>(
    String title,
    List<T> items,
    String type,
    IconData icon,
    Color color,
    Widget Function(T) itemBuilder,
    Widget Function(T, ValueChanged<T>) formBuilder,
    Future<void> Function(String, T, String) updateFunction,
    Future<List<T>> Function(String, String) fetchFunction,
    Future<void> Function(T, String) addFunction,
    Future<void> Function(String, String) deleteFunction,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildSection called for $title, items count: ${items.length}');
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: Icon(icon, color: color, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
          ),
          children: [
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              T updatedItem = item;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    itemBuilder(item),
                    if (_editingItemId[type] == item.id) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: formBuilder(item, (newItem) {
                          updatedItem = newItem;
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _editingItemId[type] = null;
                                  debugPrint('DEBUG: Cancel editing $type, ID: ${item.id}');
                                });
                              },
                              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _updateItem(updatedItem, type, updateFunction, fetchFunction),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: _isLoading 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, 
                                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                    ),
                                  )
                                : const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            if (_addingNewItem[type]!) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    T newItem = _createNewItem<T>(type);
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: formBuilder(newItem, (updatedItem) {
                            newItem = updatedItem;
                          }),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _addingNewItem[type] = false;
                                    debugPrint('DEBUG: Cancel adding new $type');
                                  });
                                },
                                child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading ? null : () {
                                  _addItem(newItem, type, addFunction, fetchFunction);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: _isLoading 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, 
                                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                      ),
                                    )
                                  : const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _addingNewItem[type] = true;
                      debugPrint('DEBUG: Add new $type button pressed');
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add $type'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                    foregroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(Education education) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildEducationItem called for education: ${education.diploma}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        education.diploma,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            education.establishment,
            style: TextStyle(
              color: colorScheme.primary, 
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            education.section,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          Text(
            '${DateFormat.yMMM().format(education.yearStart)} - ${education.present ? 'Present' : (education.yearEnd != null ? DateFormat.yMMM().format(education.yearEnd!) : '')}',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Education'] = education.id;
                debugPrint('DEBUG: Edit button pressed for Education: ${education.diploma}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(education.id, 'Education', _cvService.deleteEducation, _cvService.getEducation),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(Experience experience) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildExperienceItem called for experience: ${experience.job}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        experience.job,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            experience.company,
            style: TextStyle(
              color: colorScheme.secondary, 
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            experience.taskDescription,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${DateFormat.yMMM().format(experience.start)} - ${experience.present ? 'Present' : (experience.end != null ? DateFormat.yMMM().format(experience.end!) : '')}',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Experience'] = experience.id;
                debugPrint('DEBUG: Edit button pressed for Experience: ${experience.job}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(experience.id, 'Experience', _cvService.deleteExperience, _cvService.getExperience),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification certification) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildCertificationItem called for certification: ${certification.domaine}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.verified, color: colorScheme.secondary, size: 20),
      ),
      title: Text(
        certification.credential,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            certification.domaine,
            style: TextStyle(
              color: colorScheme.secondary, 
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            DateFormat.yMMM().format(certification.date),
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Certification'] = certification.id;
                debugPrint('DEBUG: Edit button pressed for Certification: ${certification.domaine}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(certification.id, 'Certification', _cvService.deleteCertification, _cvService.getCertifications),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillItem(Skill skill) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildSkillItem called for skill: ${skill.name}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.star, color: colorScheme.secondary, size: 20),
      ),
      title: Text(
        skill.name,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          Text('Level: ', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${skill.level}',
              style: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Skill'] = skill.id;
                debugPrint('DEBUG: Edit button pressed for Skill: ${skill.name}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(skill.id, 'Skill', _cvService.deleteSkill, _cvService.getSkills),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(Language language) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildLanguageItem called for language: ${language.name}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        language.name,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          Text('Level: ', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${language.level}',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Language'] = language.id;
                debugPrint('DEBUG: Edit button pressed for Language: ${language.name}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(language.id, 'Language', _cvService.deleteLanguage, _cvService.getLanguages),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildProjectItem called for project: ${project.title}');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.folder, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        project.title,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            project.organization,
            style: TextStyle(
              color: colorScheme.primary, 
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            project.description,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            DateFormat.yMMM().format(project.date),
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _editingItemId['Project'] = project.id;
                debugPrint('DEBUG: Edit button pressed for Project: ${project.title}');
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () => _deleteItem(project.id, 'Project', _cvService.deleteProject, _cvService.getProjects),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationForm(Education education, ValueChanged<Education> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildEducationForm called with education: $education');

    final controller1 = TextEditingController(text: education.establishment);
    final controller2 = TextEditingController(text: education.section);
    final controller3 = TextEditingController(text: education.diploma);
    DateTime yearStart = education.yearStart;
    DateTime? yearEnd = education.yearEnd;
    bool present = education.present;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller1,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Institution/University',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.school, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Establishment changed to: $value');
                education = Education(
                  id: education.id,
                  cvId: education.cvId,
                  establishment: value,
                  section: controller2.text,
                  diploma: controller3.text,
                  yearStart: yearStart,
                  yearEnd: present ? null : yearEnd,
                  present: present,
                );
                onUpdate(education);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Field of Study',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.subject, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Section changed to: $value');
                education = Education(
                  id: education.id,
                  cvId: education.cvId,
                  establishment: controller1.text,
                  section: value,
                  diploma: controller3.text,
                  yearStart: yearStart,
                  yearEnd: present ? null : yearEnd,
                  present: present,
                );
                onUpdate(education);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Degree/Diploma',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.workspace_premium, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Diploma changed to: $value');
                education = Education(
                  id: education.id,
                  cvId: education.cvId,
                  establishment: controller1.text,
                  section: controller2.text,
                  diploma: value,
                  yearStart: yearStart,
                  yearEnd: present ? null : yearEnd,
                  present: present,
                );
                onUpdate(education);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      debugPrint('DEBUG: Start Year picker tapped, current yearStart: $yearStart');
                      final date = await showDatePicker(
                        context: context,
                        initialDate: yearStart,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: colorScheme,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          yearStart = date;
                          debugPrint('DEBUG: Start Year selected: $yearStart');
                          education = Education(
                            id: education.id,
                            cvId: education.cvId,
                            establishment: controller1.text,
                            section: controller2.text,
                            diploma: controller3.text,
                            yearStart: yearStart,
                            yearEnd: present ? null : yearEnd,
                            present: present,
                          );
                          onUpdate(education);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMM().format(yearStart),
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (!present)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        debugPrint('DEBUG: End Year picker tapped, current yearEnd: $yearEnd');
                        final date = await showDatePicker(
                          context: context,
                          initialDate: yearEnd ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: colorScheme,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            yearEnd = date;
                            debugPrint('DEBUG: End Year selected: $yearEnd');
                            education = Education(
                              id: education.id,
                              cvId: education.cvId,
                              establishment: controller1.text,
                              section: controller2.text,
                              diploma: controller3.text,
                              yearStart: yearStart,
                              yearEnd: yearEnd,
                              present: present,
                            );
                            onUpdate(education);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            Text(
                              yearEnd == null ? 'End Date' : DateFormat.yMMM().format(yearEnd!),
                              style: TextStyle(
                                fontSize: 16,
                                color: yearEnd == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (present)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.primary),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.school, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Currently Studying',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Currently studying here', style: TextStyle(color: colorScheme.onSurface)),
              value: present,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    present = value;
                    debugPrint('DEBUG: Present checkbox changed to: $present');
                    education = Education(
                      id: education.id,
                      cvId: education.cvId,
                      establishment: controller1.text,
                      section: controller2.text,
                      diploma: controller3.text,
                      yearStart: yearStart,
                      yearEnd: present ? null : yearEnd,
                      present: present,
                    );
                    onUpdate(education);
                  });
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: colorScheme.surface,
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildExperienceForm(Experience experience, ValueChanged<Experience> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildExperienceForm called with experience: $experience');

    final controller1 = TextEditingController(text: experience.company);
    final controller2 = TextEditingController(text: experience.job);
    final controller3 = TextEditingController(text: experience.taskDescription);
    DateTime start = experience.start;
    DateTime? end = experience.end;
    bool present = experience.present;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller1,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Company',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.business, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Company changed to: $value');
                experience = Experience(
                  id: experience.id,
                  cvId: experience.cvId,
                  company: value,
                  job: controller2.text,
                  taskDescription: controller3.text,
                  start: start,
                  end: present ? null : end,
                  present: present,
                );
                onUpdate(experience);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Job Title',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.work, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Job changed to: $value');
                experience = Experience(
                  id: experience.id,
                  cvId: experience.cvId,
                  company: controller1.text,
                  job: value,
                  taskDescription: controller3.text,
                  start: start,
                  end: present ? null : end,
                  present: present,
                );
                onUpdate(experience);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Job Description',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.description, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              maxLines: 4,
              onChanged: (value) {
                debugPrint('DEBUG: Task Description changed to: $value');
                experience = Experience(
                  id: experience.id,
                  cvId: experience.cvId,
                  company: controller1.text,
                  job: controller2.text,
                  taskDescription: value,
                  start: start,
                  end: present ? null : end,
                  present: present,
                );
                onUpdate(experience);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      debugPrint('DEBUG: Start Date picker tapped, current start: $start');
                      final date = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: colorScheme,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          start = date;
                          debugPrint('DEBUG: Start Date selected: $start');
                          experience = Experience(
                            id: experience.id,
                            cvId: experience.cvId,
                            company: controller1.text,
                            job: controller2.text,
                            taskDescription: controller3.text,
                            start: start,
                            end: present ? null : end,
                            present: present,
                          );
                          onUpdate(experience);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMM().format(start),
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (!present)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        debugPrint('DEBUG: End Date picker tapped, current end: $end');
                        final date = await showDatePicker(
                          context: context,
                          initialDate: end ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: colorScheme,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            end = date;
                            debugPrint('DEBUG: End Date selected: $end');
                            experience = Experience(
                              id: experience.id,
                              cvId: experience.cvId,
                              company: controller1.text,
                              job: controller2.text,
                              taskDescription: controller3.text,
                              start: start,
                              end: end,
                              present: present,
                            );
                            onUpdate(experience);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            Text(
                              end == null ? 'End Date' : DateFormat.yMMM().format(end!),
                              style: TextStyle(
                                fontSize: 16,
                                color: end == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (present)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.secondary),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.secondary.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.work, color: colorScheme.secondary),
                          const SizedBox(width: 12),
                          Text(
                            'Currently Working',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Currently working here', style: TextStyle(color: colorScheme.onSurface)),
              value: present,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    present = value;
                    debugPrint('DEBUG: Present checkbox changed to: $present');
                    experience = Experience(
                      id: experience.id,
                      cvId: experience.cvId,
                      company: controller1.text,
                      job: controller2.text,
                      taskDescription: controller3.text,
                      start: start,
                      end: present ? null : end,
                      present: present,
                    );
                    onUpdate(experience);
                  });
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: colorScheme.surface,
              activeColor: colorScheme.secondary,
              checkColor: colorScheme.onSecondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCertificationForm(Certification certification, ValueChanged<Certification> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildCertificationForm called with certification: $certification');

    final controller1 = TextEditingController(text: certification.domaine);
    final controller2 = TextEditingController(text: certification.credential);
    DateTime date = certification.date;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller1,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Domain/Field',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.category, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Domaine changed to: $value');
                certification = Certification(
                  id: certification.id,
                  cvId: certification.cvId,
                  domaine: value,
                  credential: controller2.text,
                  date: date,
                  certFile: certification.certFile,
                );
                onUpdate(certification);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Certification Name',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.verified, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Credential changed to: $value');
                certification = Certification(
                  id: certification.id,
                  cvId: certification.cvId,
                  domaine: controller1.text,
                  credential: value,
                  date: date,
                  certFile: certification.certFile,
                );
                onUpdate(certification);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                debugPrint('DEBUG: Date picker tapped, current date: $date');
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme,
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    date = pickedDate;
                    debugPrint('DEBUG: Date selected: $date');
                    certification = Certification(
                      id: certification.id,
                      cvId: certification.cvId,
                      domaine: controller1.text,
                      credential: controller2.text,
                      date: date,
                      certFile: certification.certFile,
                    );
                    onUpdate(certification);
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMM().format(date),
                      style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillForm(Skill skill, ValueChanged<Skill> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildSkillForm called with skill: $skill');

    final controller = TextEditingController(text: skill.name);
    int level = skill.level;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Skill Name',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.star, color: colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Skill Name changed to: $value');
                skill = Skill(
                  id: skill.id,
                  cvId: skill.cvId,
                  name: value,
                  level: level,
                );
                onUpdate(skill);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skill Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Beginner', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                      Text('Level $level', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                      Text('Expert', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: level.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        level = value.round();
                        debugPrint('DEBUG: Skill Level changed to: $level');
                        skill = Skill(
                          id: skill.id,
                          cvId: skill.cvId,
                          name: controller.text,
                          level: level,
                        );
                        onUpdate(skill);
                      });
                    },
                    activeColor: colorScheme.secondary,
                    inactiveColor: colorScheme.secondary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageForm(Language language, ValueChanged<Language> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildLanguageForm called with language: $language');

    final controller = TextEditingController(text: language.name);
    int level = language.level;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Language Name',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.language, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Language Name changed to: $value');
                language = Language(
                  id: language.id,
                  cvId: language.cvId,
                  name: value,
                  level: level,
                );
                onUpdate(language);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proficiency Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Beginner', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                      Text('Level $level', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      Text('Native', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: level.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        level = value.round();
                        debugPrint('DEBUG: Language Level changed to: $level');
                        language = Language(
                          id: language.id,
                          cvId: language.cvId,
                          name: controller.text,
                          level: level,
                        );
                        onUpdate(language);
                      });
                    },
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectForm(Project project, ValueChanged<Project> onUpdate) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('DEBUG: _buildProjectForm called with project: $project');

    final controller1 = TextEditingController(text: project.organization);
    final controller2 = TextEditingController(text: project.title);
    final controller3 = TextEditingController(text: project.description);
    DateTime date = project.date;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller1,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Organization',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.business, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Organization changed to: $value');
                project = Project(
                  id: project.id,
                  cvId: project.cvId,
                  organization: value,
                  title: controller2.text,
                  description: controller3.text,
                  date: date,
                );
                onUpdate(project);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Project Title',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.folder, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                debugPrint('DEBUG: Title changed to: $value');
                project = Project(
                  id: project.id,
                  cvId: project.cvId,
                  organization: controller1.text,
                  title: value,
                  description: controller3.text,
                  date: date,
                );
                onUpdate(project);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Project Description',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                prefixIcon: Icon(Icons.description, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              maxLines: 4,
              onChanged: (value) {
                debugPrint('DEBUG: Description changed to: $value');
                project = Project(
                  id: project.id,
                  cvId: project.cvId,
                  organization: controller1.text,
                  title: controller2.text,
                  description: value,
                  date: date,
                );
                onUpdate(project);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                debugPrint('DEBUG: Date picker tapped, current date: $date');
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme,
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    date = pickedDate;
                    debugPrint('DEBUG: Date selected: $date');
                    project = Project(
                      id: project.id,
                      cvId: project.cvId,
                      organization: controller1.text,
                      title: controller2.text,
                      description: controller3.text,
                      date: date,
                    );
                    onUpdate(project);
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMM().format(date),
                      style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
