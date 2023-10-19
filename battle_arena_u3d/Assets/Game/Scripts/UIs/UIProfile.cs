using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UIProfile : MonoBehaviour
{
    [SerializeField] TMP_Text _textName;
    [SerializeField] TMP_Text _textHP;
    [SerializeField] Slider _sliderHP;
    [SerializeField] TMP_Text _totalKill;


    public void SetName(string name)
    {
        _textName.text = name.ToString();
    }

    public void SetHP(int hp, int hpMax)
    {
        _textHP.text = hp.ToString();
        _sliderHP.maxValue = hpMax;
        _sliderHP.value = hp;
    }

    public void SetEnemiesKill(int amount)
    {
        _totalKill.text = amount.ToString();
    }
}
