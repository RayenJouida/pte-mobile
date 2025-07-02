import 'package:flutter/material.dart';
import 'package:pte_mobile/models/cv/certification.dart';
import 'package:pte_mobile/models/cv/cv.dart';
import 'package:pte_mobile/models/cv/education.dart';
import 'package:pte_mobile/models/cv/experience.dart';
import 'package:pte_mobile/models/cv/language.dart';
import 'package:pte_mobile/models/cv/project.dart';
import 'package:pte_mobile/models/cv/skill.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/cv/update_resume.dart';
import 'package:pte_mobile/services/cv_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pte_mobile/services/user_service.dart';

// Define a class to hold the updated data for returning (used by UpdateResumeScreen)
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

class CVProvider with ChangeNotifier {
  Cv? cv;
  List<Education> educations = [];
  List<Experience> experiences = [];
  List<Certification> certifications = [];
  List<Skill> skills = [];
  List<Language> languages = [];
  List<Project> projects = [];
  bool isLoading = false;
  String? error;

  final CvService _cvService = CvService();

  Future<void> fetchCVData(String userId, String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final cvs = await _cvService.getUserCV(userId, token);
      cv = cvs.isNotEmpty ? cvs.first : null;

      if (cv != null) {
        educations = await _cvService.getEducation(cv!.id, token);
        experiences = await _cvService.getExperience(cv!.id, token);
        certifications = await _cvService.getCertifications(cv!.id, token);
        skills = await _cvService.getSkills(cv!.id, token);
        languages = await _cvService.getLanguages(cv!.id, token);
        projects = await _cvService.getProjects(cv!.id, token);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Method to update CV data without fetching from API
  void updateCVData(UpdatedCVData updatedData) {
    cv = updatedData.cv;
    educations = updatedData.educations;
    experiences = updatedData.experiences;
    certifications = updatedData.certifications;
    skills = updatedData.skills;
    languages = updatedData.languages;
    projects = updatedData.projects;
    notifyListeners();
  }

  Future<void> updateSummary(String cvId, String summary, String userId, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateSummary(cvId, summary, userId, token);
      // Create a new Cv instance to ensure the change triggers a rebuild
      cv = Cv(
        id: cvId,
        userId: userId,
        summary: summary,
        educationIds: cv?.educationIds ?? [],
        experienceIds: cv?.experienceIds ?? [],
        certificationIds: cv?.certificationIds ?? [],
        projectIds: cv?.projectIds ?? [],
        skillIds: cv?.skillIds ?? [],
        languageIds: cv?.languageIds ?? [],
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEducation(Education education, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addEducation(education, token);
      educations = await _cvService.getEducation(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEducation(String id, Education education, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateEducation(id, education, token);
      educations = await _cvService.getEducation(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEducation(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteEducation(id, token);
      educations = await _cvService.getEducation(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExperience(Experience experience, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addExperience(experience, token);
      experiences = await _cvService.getExperience(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExperience(String id, Experience experience, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateExperience(id, experience, token);
      experiences = await _cvService.getExperience(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExperience(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteExperience(id, token);
      experiences = await _cvService.getExperience(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCertification(Certification certification, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addCertification(certification, token);
      certifications = await _cvService.getCertifications(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCertification(String id, Certification certification, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateCertification(id, certification, token);
      certifications = await _cvService.getCertifications(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCertification(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteCertification(id, token);
      certifications = await _cvService.getCertifications(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSkill(Skill skill, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addSkill(skill, token);
      skills = await _cvService.getSkills(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSkill(String id, Skill skill, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateSkill(id, skill, token);
      skills = await _cvService.getSkills(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSkill(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteSkill(id, token);
      skills = await _cvService.getSkills(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLanguage(Language language, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addLanguage(language, token);
      languages = await _cvService.getLanguages(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLanguage(String id, Language language, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateLanguage(id, language, token);
      languages = await _cvService.getLanguages(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLanguage(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteLanguage(id, token);
      languages = await _cvService.getLanguages(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProject(Project project, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.addProject(project, token);
      projects = await _cvService.getProjects(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProject(String id, Project project, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.updateProject(id, project, token);
      projects = await _cvService.getProjects(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _cvService.deleteProject(id, token);
      projects = await _cvService.getProjects(cv!.id, token);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class CVManagementScreen extends StatelessWidget {
  final String userId;
  final String token;

  const CVManagementScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => CVProvider(),
      child: Builder(
        builder: (context) {
          final provider = Provider.of<CVProvider>(context, listen: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.cv == null) {
              provider.fetchCVData(userId, token);
            }
          });

          return Scaffold(
            backgroundColor: colorScheme.background,
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.chevron_left, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    'My Resume',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  centerTitle: true,
  backgroundColor: Theme.of(context).colorScheme.primary,
  actions: [
    IconButton(
      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onPrimary),
      onPressed: () async {
        if (provider.cv == null) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateResumeScreen(
              userId: userId,
              token: token,
              cv: provider.cv!,
              educations: provider.educations,
              experiences: provider.experiences,
              certifications: provider.certifications,
              skills: provider.skills,
              languages: provider.languages,
              projects: provider.projects,
            ),
          ),
        );

        if (result != null && result is UpdatedCVData) {
          provider.updateCVData(result);
        }
      },
    ),
    IconButton(
      icon: Icon(Icons.download_outlined, color: Theme.of(context).colorScheme.onPrimary),
      onPressed: () => _generateAndDownloadPDF(context, provider),
    ),
  ],
),
            body: Consumer<CVProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.cv == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No CV found',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
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
                      children: [
                        _buildHeader(provider.cv!, colorScheme),
                        _buildSummary(provider.cv!.summary, colorScheme),
                        _buildExperienceSection(provider.experiences, colorScheme),
                        _buildEducationSection(provider.educations, colorScheme),
                        _buildSkillsAndLanguagesSection(provider.skills, provider.languages, colorScheme),
                        _buildCertificationsSection(provider.certifications, colorScheme),
                        _buildProjectsSection(provider.projects, colorScheme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Cv cv, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: UserService().getUserById(cv.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          );
        }

        final userData = snapshot.data;
        final user = userData != null ? User.fromJson(userData) : null;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.onPrimary, width: 3),
                ),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user != null ? '${user.firstName} ${user.lastName}' : 'Unknown User',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, color: colorScheme.onPrimary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      user?.phone ?? 'No phone number',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(String summary, ColorScheme colorScheme) {
    if (summary.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(List<Experience> experiences, ColorScheme colorScheme) {
    if (experiences.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: colorScheme.secondary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Professional Experience',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...experiences.map((exp) => _buildExperienceItem(exp, colorScheme)).toList(),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(Experience experience, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.job,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      experience.company,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatDate(experience.start)} - ${_formatDate(experience.end, experience.present)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            experience.taskDescription,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<Education> educations, ColorScheme colorScheme) {
    if (educations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Education',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...educations.map((edu) => _buildEducationItem(edu, colorScheme)).toList(),
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education education, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.diploma,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  education.establishment,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  education.section,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_formatDate(education.yearStart)} - ${_formatDate(education.yearEnd, education.present)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsAndLanguagesSection(List<Skill> skills, List<Language> languages, ColorScheme colorScheme) {
    if (skills.isEmpty && languages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (skills.isNotEmpty) 
            Expanded(child: _buildSkillsSubsection(skills, colorScheme)),
          if (skills.isNotEmpty && languages.isNotEmpty) 
            const SizedBox(width: 16),
          if (languages.isNotEmpty) 
            Expanded(child: _buildLanguagesSubsection(languages, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSkillsSubsection(List<Skill> skills, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, color: colorScheme.secondary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Skills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => _buildSkillChip(skill, colorScheme)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(Skill skill, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${skill.level}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSubsection(List<Language> languages, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Languages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: languages.map((lang) => _buildLanguageItem(lang, colorScheme)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageItem(Language language, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            language.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${language.level}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(List<Certification> certifications, ColorScheme colorScheme) {
    if (certifications.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: colorScheme.secondary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Certifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...certifications.map((cert) => _buildCertificationItem(cert, colorScheme)).toList(),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification certification, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.verified, color: colorScheme.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certification.credential,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certification.domaine,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(certification.date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(List<Project> projects, ColorScheme colorScheme) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_outlined, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...projects.map((proj) => _buildProjectItem(proj, colorScheme)).toList(),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.organization,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(project.date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, [bool present = false]) {
    if (date == null) return present ? 'Present' : '';
    return DateFormat.yMMM().format(date) + (present ? ' - Present' : '');
  }

  Future<void> _generateAndDownloadPDF(BuildContext context, CVProvider provider) async {
    final pdf = pw.Document();
    final userData = await UserService().getUserById(provider.cv!.userId);
    final user = User.fromJson(userData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${user.firstName} ${user.lastName}', 
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Contact: ${user.email}', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(provider.cv!.summary, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            if (provider.educations.isNotEmpty) ...[
              pw.Text('Education', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.educations.map((edu) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${edu.diploma} - ${edu.establishment}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('${edu.section} (${_formatDate(edu.yearStart)} - ${_formatDate(edu.yearEnd, edu.present)})',
                          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                    ],
                  )),
              pw.SizedBox(height: 20),
            ],
            if (provider.experiences.isNotEmpty) ...[
              pw.Text('Experience', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.experiences.map((exp) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(exp.job, style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('${exp.company} (${_formatDate(exp.start)} - ${_formatDate(exp.end, exp.present)})',
                          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                      pw.Text(exp.taskDescription, style: const pw.TextStyle(fontSize: 14)),
                    ],
                  )),
              pw.SizedBox(height: 20),
            ],
            if (provider.certifications.isNotEmpty) ...[
              pw.Text('Certifications', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.certifications.map((cert) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${cert.domaine} - ${cert.credential}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text(_formatDate(cert.date), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                    ],
                  )),
              pw.SizedBox(height: 20),
            ],
            if (provider.skills.isNotEmpty) ...[
              pw.Text('Skills', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.skills.map((skill) => pw.Text('${skill.name} (Level: ${skill.level})',
                  style: const pw.TextStyle(fontSize: 16))),
              pw.SizedBox(height: 20),
            ],
            if (provider.languages.isNotEmpty) ...[
              pw.Text('Languages', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.languages.map((lang) => pw.Text('${lang.name} (Level: ${lang.level})',
                  style: const pw.TextStyle(fontSize: 16))),
              pw.SizedBox(height: 20),
            ],
            if (provider.projects.isNotEmpty) ...[
              pw.Text('Projects', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ...provider.projects.map((proj) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${proj.title} - ${proj.organization}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text(proj.description, style: const pw.TextStyle(fontSize: 14)),
                      pw.Text(_formatDate(proj.date), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                    ],
                  )),
            ],
          ],
        ),
      ),
    );

    final name = provider.cv!.userId.split('@')[0].replaceAll(' ', '_');
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '$name-Resume.pdf',
    );
  }
}

class EducationTab extends StatelessWidget {
  final List<Education> educations;
  final String cvId;
  final String token;

  const EducationTab({Key? key, required this.educations, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: educations.length,
            itemBuilder: (context, index) {
              final education = educations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: EducationFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  education: education,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Education', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this education entry?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteEducation(education.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Education deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: EducationFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EducationFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Education? education;

  const EducationFormScreen({Key? key, required this.cvId, required this.token, this.education}) : super(key: key);

  @override
  _EducationFormScreenState createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<EducationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _establishmentController;
  late TextEditingController _sectionController;
  late TextEditingController _diplomaController;
  DateTime? _yearStart;
  DateTime? _yearEnd;
  bool _present = false;

  @override
  void initState() {
    super.initState();
    _establishmentController = TextEditingController(text: widget.education?.establishment ?? '');
    _sectionController = TextEditingController(text: widget.education?.section ?? '');
    _diplomaController = TextEditingController(text: widget.education?.diploma ?? '');
    _yearStart = widget.education?.yearStart;
    _yearEnd = widget.education?.yearEnd;
    _present = widget.education?.present ?? false;
  }

  @override
  void dispose() {
    _establishmentController.dispose();
    _sectionController.dispose();
    _diplomaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.education == null ? 'Add Education' : 'Edit Education',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.education == null ? 'Add New Education' : 'Edit Education',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _establishmentController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Institution is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sectionController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Field of study is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diplomaController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Degree is required' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _yearStart ?? DateTime.now(),
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
                          if (date != null) setState(() => _yearStart = date);
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
                                _yearStart == null
                                    ? 'Start Date'
                                    : DateFormat.yMMM().format(_yearStart!),
                                style: TextStyle(
                                  color: _yearStart == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!_present)
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _yearEnd ?? DateTime.now(),
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
                            if (date != null) setState(() => _yearEnd = date);
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
                                  _yearEnd == null
                                      ? 'End Date'
                                      : DateFormat.yMMM().format(_yearEnd!),
                                  style: TextStyle(
                                    color: _yearEnd == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_present)
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
                  value: _present,
                  onChanged: (value) {
                    setState(() {
                      _present = value!;
                      if (_present) _yearEnd = null;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  tileColor: colorScheme.surface,
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _yearStart != null) {
                        final education = Education(
                          id: widget.education?.id ?? '',
                          cvId: widget.cvId,
                          establishment: _establishmentController.text,
                          section: _sectionController.text,
                          diploma: _diplomaController.text,
                          yearStart: _yearStart!,
                          yearEnd: _present ? null : _yearEnd,
                          present: _present,
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.education == null) {
                            await provider.addEducation(education, widget.token);
                          } else {
                            await provider.updateEducation(widget.education!.id, education, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.education == null ? 'Education added successfully' : 'Education updated successfully'),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      } else if (_yearStart == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please select a start date'),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: Text(
                      widget.education == null ? 'Add Education' : 'Update Education',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExperienceTab extends StatelessWidget {
  final List<Experience> experiences;
  final String cvId;
  final String token;

  const ExperienceTab({Key? key, required this.experiences, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: experiences.length,
            itemBuilder: (context, index) {
              final experience = experiences[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 4),
                      Text(
                        experience.taskDescription,
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: ExperienceFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  experience: experience,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Experience', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this experience?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteExperience(experience.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Experience deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: ExperienceFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Experience'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExperienceFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Experience? experience;

  const ExperienceFormScreen({Key? key, required this.cvId, required this.token, this.experience}) : super(key: key);

  @override
  _ExperienceFormScreenState createState() => _ExperienceFormScreenState();
}

class _ExperienceFormScreenState extends State<ExperienceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _jobController;
  late TextEditingController _taskDescriptionController;
  DateTime? _start;
  DateTime? _end;
  bool _present = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.experience?.company ?? '');
    _jobController = TextEditingController(text: widget.experience?.job ?? '');
    _taskDescriptionController = TextEditingController(text: widget.experience?.taskDescription ?? '');
    _start = widget.experience?.start;
    _end = widget.experience?.end;
    _present = widget.experience?.present ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.experience == null ? 'Add Experience' : 'Edit Experience',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.experience == null ? 'Add New Experience' : 'Edit Experience',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _companyController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Company is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jobController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Job title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taskDescriptionController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'Job description is required' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _start ?? DateTime.now(),
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
                          if (date != null) setState(() => _start = date);
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
                                _start == null
                                    ? 'Start Date'
                                    : DateFormat.yMMM().format(_start!),
                                style: TextStyle(
                                  color: _start == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!_present)
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _end ?? DateTime.now(),
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
                            if (date != null) setState(() => _end = date);
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
                                  _end == null
                                      ? 'End Date'
                                      : DateFormat.yMMM().format(_end!),
                                  style: TextStyle(
                                    color: _end == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_present)
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
                  value: _present,
                  onChanged: (value) {
                    setState(() {
                      _present = value!;
                      if (_present) _end = null;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  tileColor: colorScheme.surface,
                  activeColor: colorScheme.secondary,
                  checkColor: colorScheme.onSecondary,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _start != null) {
                        final experience = Experience(
                          id: widget.experience?.id ?? '',
                          cvId: widget.cvId,
                          company: _companyController.text,
                          job: _jobController.text,
                          taskDescription: _taskDescriptionController.text,
                          start: _start!,
                          end: _present ? null : _end,
                          present: _present,
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.experience == null) {
                            await provider.addExperience(experience, widget.token);
                          } else {
                            await provider.updateExperience(widget.experience!.id, experience, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.experience == null ? 'Experience added successfully' : 'Experience updated successfully'),
                              backgroundColor: colorScheme.secondary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      } else if (_start == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please select a start date'),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                    child: Text(
                      widget.experience == null ? 'Add Experience' : 'Update Experience',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CertificationsTab extends StatelessWidget {
  final List<Certification> certifications;
  final String cvId;
  final String token;

  const CertificationsTab({Key? key, required this.certifications, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: certifications.length,
            itemBuilder: (context, index) {
              final certification = certifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.verified, color: colorScheme.secondary),
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
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: CertificationFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  certification: certification,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Certification', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this certification?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteCertification(certification.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Certification deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: CertificationFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Certification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CertificationFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Certification? certification;

  const CertificationFormScreen({Key? key, required this.cvId, required this.token, this.certification}) : super(key: key);

  @override
  _CertificationFormScreenState createState() => _CertificationFormScreenState();
}

class _CertificationFormScreenState extends State<CertificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _domaineController;
  late TextEditingController _credentialController;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _domaineController = TextEditingController(text: widget.certification?.domaine ?? '');
    _credentialController = TextEditingController(text: widget.certification?.credential ?? '');
    _date = widget.certification?.date;
  }

  @override
  void dispose() {
    _domaineController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.certification == null ? 'Add Certification' : 'Edit Certification',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.certification == null ? 'Add New Certification' : 'Edit Certification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _domaineController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Domain is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _credentialController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Certification name is required' : null,
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime.now(),
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
                    if (date != null) setState(() => _date = date);
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
                          _date == null
                              ? 'Select Date'
                              : DateFormat.yMMM().format(_date!),
                          style: TextStyle(
                            color: _date == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _date != null) {
                        final certification = Certification(
                          id: widget.certification?.id ?? '',
                          cvId: widget.cvId,
                          domaine: _domaineController.text,
                          credential: _credentialController.text,
                          date: _date!,
                          certFile: widget.certification?.certFile ?? '',
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.certification == null) {
                            await provider.addCertification(certification, widget.token);
                          } else {
                            await provider.updateCertification(widget.certification!.id, certification, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.certification == null ? 'Certification added successfully' : 'Certification updated successfully'),
                              backgroundColor: colorScheme.secondary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      } else if (_date == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please select a date'),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                    child: Text(
                      widget.certification == null ? 'Add Certification' : 'Update Certification',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkillsTab extends StatelessWidget {
  final List<Skill> skills;
  final String cvId;
  final String token;

  const SkillsTab({Key? key, required this.skills, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.star, color: colorScheme.secondary),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: SkillFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  skill: skill,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Skill', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this skill?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteSkill(skill.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Skill deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: SkillFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Skill'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SkillFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Skill? skill;

  const SkillFormScreen({Key? key, required this.cvId, required this.token, this.skill}) : super(key: key);

  @override
  _SkillFormScreenState createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends State<SkillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _level = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill?.name ?? '');
    _level = widget.skill?.level ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.skill == null ? 'Add Skill' : 'Edit Skill',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.skill == null ? 'Add New Skill' : 'Edit Skill',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Skill name is required' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Skill Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Beginner', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                          Text('Level $_level', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                          Text('Expert', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _level.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        onChanged: (value) => setState(() => _level = value.round()),
                        activeColor: colorScheme.secondary,
                        inactiveColor: colorScheme.secondary.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final skill = Skill(
                          id: widget.skill?.id ?? '',
                          cvId: widget.cvId,
                          name: _nameController.text,
                          level: _level,
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.skill == null) {
                            await provider.addSkill(skill, widget.token);
                          } else {
                            await provider.updateSkill(widget.skill!.id, skill, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.skill == null ? 'Skill added successfully' : 'Skill updated successfully'),
                              backgroundColor: colorScheme.secondary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                    child: Text(
                      widget.skill == null ? 'Add Skill' : 'Update Skill',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguagesTab extends StatelessWidget {
  final List<Language> languages;
  final String cvId;
  final String token;

  const LanguagesTab({Key? key, required this.languages, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.language, color: colorScheme.primary),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: LanguageFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  language: language,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Language', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this language?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteLanguage(language.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Language deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: LanguageFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Language'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LanguageFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Language? language;

  const LanguageFormScreen({Key? key, required this.cvId, required this.token, this.language}) : super(key: key);

  @override
  _LanguageFormScreenState createState() => _LanguageFormScreenState();
}

class _LanguageFormScreenState extends State<LanguageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _level = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.language?.name ?? '');
    _level = widget.language?.level ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.language == null ? 'Add Language' : 'Edit Language',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.language == null ? 'Add New Language' : 'Edit Language',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Language name is required' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Proficiency Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Beginner', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                          Text('Level $_level', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                          Text('Native', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _level.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        onChanged: (value) => setState(() => _level = value.round()),
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.primary.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final language = Language(
                          id: widget.language?.id ?? '',
                          cvId: widget.cvId,
                          name: _nameController.text,
                          level: _level,
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.language == null) {
                            await provider.addLanguage(language, widget.token);
                          } else {
                            await provider.updateLanguage(widget.language!.id, language, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.language == null ? 'Language added successfully' : 'Language updated successfully'),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: Text(
                      widget.language == null ? 'Add Language' : 'Update Language',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectsTab extends StatelessWidget {
  final List<Project> projects;
  final String cvId;
  final String token;

  const ProjectsTab({Key? key, required this.projects, required this.cvId, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder, color: colorScheme.primary),
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
                      const SizedBox(height: 4),
                      Text(
                        project.description,
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<CVProvider>(context, listen: false),
                                child: ProjectFormScreen(
                                  cvId: cvId,
                                  token: token,
                                  project: project,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.surface,
                              title: Text('Delete Project', style: TextStyle(color: colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete this project?', style: TextStyle(color: colorScheme.onSurface)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await Provider.of<CVProvider>(context, listen: false)
                                  .deleteProject(project.id, token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Project deleted successfully'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: Provider.of<CVProvider>(context, listen: false),
                      child: ProjectFormScreen(cvId: cvId, token: token),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProjectFormScreen extends StatefulWidget {
  final String cvId;
  final String token;
  final Project? project;

  const ProjectFormScreen({Key? key, required this.cvId, required this.token, this.project}) : super(key: key);

  @override
  _ProjectFormScreenState createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _organizationController;
  late TextEditingController _descriptionController;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.title ?? '');
    _organizationController = TextEditingController(text: widget.project?.organization ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    _date = widget.project?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.project == null ? 'Add Project' : 'Edit Project',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project == null ? 'Add New Project' : 'Edit Project',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Project title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizationController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) => value!.isEmpty ? 'Organization is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'Project description is required' : null,
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime.now(),
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
                    if (date != null) setState(() => _date = date);
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
                          _date == null
                              ? 'Select Date'
                              : DateFormat.yMMM().format(_date!),
                          style: TextStyle(
                            color: _date == null ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _date != null) {
                        final project = Project(
                          id: widget.project?.id ?? '',
                          cvId: widget.cvId,
                          title: _titleController.text,
                          organization: _organizationController.text,
                          description: _descriptionController.text,
                          date: _date!,
                        );

                        try {
                          final provider = Provider.of<CVProvider>(context, listen: false);
                          if (widget.project == null) {
                            await provider.addProject(project, widget.token);
                          } else {
                            await provider.updateProject(widget.project!.id, project, widget.token);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.project == null ? 'Project added successfully' : 'Project updated successfully'),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      } else if (_date == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please select a date'),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: Text(
                      widget.project == null ? 'Add Project' : 'Update Project',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
