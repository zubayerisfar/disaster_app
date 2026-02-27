class MentalHealthAssessment {
  final int schoolingStatus;
  final int mediaExposure;
  final int physicalAbuse;
  final int sexualAbuse;
  final int academicPerformance;
  final int freedomToMove;
  final int expressionOfOpinion;
  final int communicationWithParents;
  final int communicationWithFriends;
  final int confrontWrongActs;
  final int engagedMarriageFixed;
  final int discussionOfSexualProblems;
  final int discussionAboutRelationship;
  final int medicalSymptoms;
  final int impulsiveBehaviour;
  final int familyProblems;
  final int divorce;
  final int partnerAbuse;
  final int substanceAbuse;
  final int relationshipProblems;
  final int peerPressure;

  MentalHealthAssessment({
    required this.schoolingStatus,
    required this.mediaExposure,
    required this.physicalAbuse,
    required this.sexualAbuse,
    required this.academicPerformance,
    required this.freedomToMove,
    required this.expressionOfOpinion,
    required this.communicationWithParents,
    required this.communicationWithFriends,
    required this.confrontWrongActs,
    required this.engagedMarriageFixed,
    required this.discussionOfSexualProblems,
    required this.discussionAboutRelationship,
    required this.medicalSymptoms,
    required this.impulsiveBehaviour,
    required this.familyProblems,
    required this.divorce,
    required this.partnerAbuse,
    required this.substanceAbuse,
    required this.relationshipProblems,
    required this.peerPressure,
  });

  Map<String, dynamic> toJson() {
    return {
      'Schooling_Status': schoolingStatus,
      'Media_Exposure': mediaExposure,
      'Physical_Abuse': physicalAbuse,
      'Sexual_Abuse': sexualAbuse,
      'Academic_Performance': academicPerformance,
      'Freedom_to_Move': freedomToMove,
      'Expression_of_Opinion': expressionOfOpinion,
      'Communication_with_Parents': communicationWithParents,
      'Communication_with_Friends': communicationWithFriends,
      'Confront_Wrong_Acts': confrontWrongActs,
      'Engaged_Marriage_Fixed': engagedMarriageFixed,
      'Discussion_of_Sexual_Problems': discussionOfSexualProblems,
      'Discussion_about_Relationship': discussionAboutRelationship,
      'Medical_Symptoms': medicalSymptoms,
      'Impulsive_Behaviour': impulsiveBehaviour,
      'Family_Problems': familyProblems,
      'Divorce': divorce,
      'Partner_Abuse': partnerAbuse,
      'Substance_Abuse': substanceAbuse,
      'Relationship_Problems': relationshipProblems,
      'Peer_Pressure': peerPressure,
    };
  }
}

// Questions in Bengali with answer options
class MentalHealthQuestion {
  final String question;
  final List<String> options;
  final String field;

  const MentalHealthQuestion({
    required this.question,
    required this.options,
    required this.field,
  });
}

// Bengali questions for mental health assessment
const List<MentalHealthQuestion> mentalHealthQuestions = [
  MentalHealthQuestion(
    question: 'শিক্ষার অবস্থা',
    options: ['না', 'হ্যাঁ', 'না প্রযোজ্য'],
    field: 'schoolingStatus',
  ),
  MentalHealthQuestion(
    question: 'মিডিয়ার সংস্পর্শ (টিভি, সোশ্যাল মিডিয়া)',
    options: ['কম', 'মাঝারি', 'বেশি'],
    field: 'mediaExposure',
  ),
  MentalHealthQuestion(
    question: 'শারীরিক নির্যাতনের অভিজ্ঞতা',
    options: ['না', 'হ্যাঁ, অতীতে', 'হ্যাঁ, বর্তমানে'],
    field: 'physicalAbuse',
  ),
  MentalHealthQuestion(
    question: 'যৌন নির্যাতনের অভিজ্ঞতা',
    options: ['না', 'হ্যাঁ, অতীতে', 'হ্যাঁ, বর্তমানে'],
    field: 'sexualAbuse',
  ),
  MentalHealthQuestion(
    question: 'একাডেমিক পারফরম্যান্স',
    options: ['ভালো', 'মাঝারি', 'খারাপ'],
    field: 'academicPerformance',
  ),
  MentalHealthQuestion(
    question: 'চলাফেরার স্বাধীনতা',
    options: ['পূর্ণ স্বাধীনতা', 'সীমিত', 'খুবই সীমিত'],
    field: 'freedomToMove',
  ),
  MentalHealthQuestion(
    question: 'মতামত প্রকাশের সুযোগ',
    options: ['সবসময়', 'মাঝেমধ্যে', 'কদাচিৎ'],
    field: 'expressionOfOpinion',
  ),
  MentalHealthQuestion(
    question: 'বাবা-মায়ের সাথে যোগাযোগ',
    options: ['ভালো', 'মাঝারি', 'দুর্বল'],
    field: 'communicationWithParents',
  ),
  MentalHealthQuestion(
    question: 'বন্ধুদের সাথে যোগাযোগ',
    options: ['ভালো', 'মাঝারি', 'দুর্বল'],
    field: 'communicationWithFriends',
  ),
  MentalHealthQuestion(
    question: 'অন্যায়ের বিরুদ্ধে প্রতিবাদ করার ক্ষমতা',
    options: ['সবসময়', 'মাঝেমধ্যে', 'কখনো না'],
    field: 'confrontWrongActs',
  ),
  MentalHealthQuestion(
    question: 'বাগদান/বিয়ে নির্ধারিত',
    options: ['না', 'হ্যাঁ, সম্মতিতে', 'হ্যাঁ, জোরপূর্বক'],
    field: 'engagedMarriageFixed',
  ),
  MentalHealthQuestion(
    question: 'যৌন সমস্যা নিয়ে আলোচনার সুযোগ',
    options: ['আছে', 'সীমিত', 'নেই'],
    field: 'discussionOfSexualProblems',
  ),
  MentalHealthQuestion(
    question: 'সম্পর্ক নিয়ে আলোচনার সুযোগ',
    options: ['আছে', 'সীমিত', 'নেই'],
    field: 'discussionAboutRelationship',
  ),
  MentalHealthQuestion(
    question: 'চিকিৎসা সংক্রান্ত লক্ষণ (মাথাব্যথা, ঘুমের সমস্যা)',
    options: ['না', 'মাঝেমধ্যে', 'প্রায়ই'],
    field: 'medicalSymptoms',
  ),
  MentalHealthQuestion(
    question: 'আবেগপ্রবণ আচরণ',
    options: ['না', 'মাঝেমধ্যে', 'প্রায়ই'],
    field: 'impulsiveBehaviour',
  ),
  MentalHealthQuestion(
    question: 'পারিবারিক সমস্যা',
    options: ['না', 'মাঝেমধ্যে', 'প্রায়ই'],
    field: 'familyProblems',
  ),
  MentalHealthQuestion(
    question: 'তালাক/পরিবার ভাঙন',
    options: ['না', 'প্রক্রিয়াধীন', 'হ্যাঁ'],
    field: 'divorce',
  ),
  MentalHealthQuestion(
    question: 'সঙ্গীর দ্বারা নির্যাতন',
    options: ['না', 'হ্যাঁ, অতীতে', 'হ্যাঁ, বর্তমানে'],
    field: 'partnerAbuse',
  ),
  MentalHealthQuestion(
    question: 'মাদকাসক্তি (নিজে বা পরিবারে)',
    options: ['না', 'পরিবারে', 'নিজে'],
    field: 'substanceAbuse',
  ),
  MentalHealthQuestion(
    question: 'সম্পর্কের সমস্যা',
    options: ['না', 'মাঝেমধ্যে', 'প্রায়ই'],
    field: 'relationshipProblems',
  ),
  MentalHealthQuestion(
    question: 'সমবয়সীদের চাপ',
    options: ['না', 'মাঝেমধ্যে', 'প্রায়ই'],
    field: 'peerPressure',
  ),
];
