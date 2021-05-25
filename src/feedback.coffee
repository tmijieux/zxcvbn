scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      #"Use a few words, avoid common phrases"
      "Utilisez quelques mots, évitez les phrases communes."
      #"No need for symbols, digits, or uppercase letters"
      "L'utilisation de symboles, chiffres ou des lettres capitales n'est pas obligatoire."
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    # extra_feedback = 'Add another word or two. Uncommon words are better.'
    extra_feedback = "Ajoutez un mot ou deux. Préférez les mots rares."
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          # 'Straight rows of keys are easy to guess'
          "Des rangées de caractères sur le clavier sont faciles à deviner."
        else
          # 'Short keyboard patterns are easy to guess'
          "Des caractères contigus sur le clavier sont facile à deviner."
        warning: warning
        suggestions: [
          #'Use a longer keyboard pattern with more turns'
          "Utilisez plus de caractères moins contigus."
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          #"Repeats like 'aaa' are easy to guess"
          "Des répétitions telles que 'aaa' sont faciles à deviner."
        else
          #'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
          "Une répétition telle que 'abcabcabc' est à peine plus sûre que 'abc'."
        warning: warning
        suggestions: [
          #'Avoid repeated words and characters'
          "Évitez les répétitions de mots ou de lettres"
        ]

      when 'sequence'
        #warning: "Sequences like abc or 6543 are easy to guess"
        warning: "Les séquences comme 'abc' ou '6543' sont faciles à devinez"
        suggestions: [
          #'Avoid sequences'
          "Évitez les séquences"
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          # warning: "Recent years are easy to guess"
          warning: "Les années récentes sont faciles à deviner."
          suggestions: [
            #'Avoid recent years'
            "Évitez les années récentes."
            #'Avoid years that are associated with you'
            "Évitez les années facilement associables à votre personne."
          ]

      when 'date'
        #warning: "Dates are often easy to guess"
        warning: "Les dates sont faciles à deviner."
        suggestions: [
          #'Avoid dates and years that are associated with you'
          "Évitez les dates et années facilement associables à votre personne."
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords' or match.dictionary_name == 'fr_passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          #'This is a top-10 common password'
          "C'est un des 10 mots de passe les plus courants !"
        else if match.rank <= 100
          #'This is a top-100 common password'
          "C'est un des 100 mots de passe les plus courants !"
        else
          #'This is a very common password'
          "C'est un mot de passe très commun."
      else if match.guesses_log10 <= 4
        #'This is similar to a commonly used password'
        "C'est trop similaire à un mot de passe très commun."
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        #'A word by itself is easy to guess'
        "Un mot seul est bien trop facile à deviner."
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names', 'nom_femme', 'nom_homme']
      if is_sole_match
        #'Names and surnames by themselves are easy to guess'
        "Un prénom ou nom seul est trop facile à deviner."
      else
        #'Common names and surnames are easy to guess'
        "Les prénoms ou noms les plus communs sont faciles à deviner."
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      #suggestions.push "Capitalization doesn't help very much"
      suggestions.push "Les majuscules n'aident pas beaucoup."
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      #suggestions.push "All-uppercase is almost as easy to guess as all-lowercase"
      suggestions.push "Tout en majuscules est aussi facile à deviner que tout en minuscules."

    if match.reversed and match.token.length >= 4
      #suggestions.push "Reversed words aren't much harder to guess"
      suggestions.push "Écrire à l'envers n'augmente pas la sûreté."
    if match.l33t
      #suggestions.push "Predictable substitutions like '@' instead of 'a' don't help very much"
      suggestions.push "Des substitutions prévisibles comme '@' pour 'a' n'aident pas vraiment.",

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
